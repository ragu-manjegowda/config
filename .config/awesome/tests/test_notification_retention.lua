#!/usr/bin/env lua

local root = os.getenv('HOME') .. '/.config/awesome/'
local retention = dofile(root .. 'library/notification-retention.lua')

local function notification(urgency, priority, hints)
    return {
        urgency = urgency or 'normal',
        _private = {
            retention_priority = priority,
            freedesktop_hints = hints,
        },
    }
end

assert(retention.limit == 10, 'notification retention limit changed')
assert(retention.priority(notification()) == 0, 'normal priority must be 0')
assert(retention.priority(notification('critical')) == 2, 'critical priority must be 2')
assert(retention.priority(notification('normal', 1)) == 1, 'explicit priority was ignored')
assert(retention.priority(notification('normal', nil, {
    ['x-awesome-retention-priority'] = 1,
})) == 1, 'D-Bus priority hint was ignored')
assert(retention.priority({}) == 0, 'malformed notifications must use default priority')
assert(retention.eviction_index({}) == nil, 'empty history has no eviction candidate')

local critical = notification('critical')
local email = notification('normal', 1)
local notifications = { critical, email }

for _ = 1, 20 do
    notifications[#notifications + 1] = notification()
    while #notifications > retention.limit do
        table.remove(notifications, retention.eviction_index(notifications))
    end
end

local found_critical = false
local found_email = false
for _, current in ipairs(notifications) do
    found_critical = found_critical or current == critical
    found_email = found_email or current == email
end

assert(#notifications == 10, 'history exceeded ten notifications')
assert(found_critical, 'critical notification was evicted before normal noise')
assert(found_email, 'sender-priority notification was evicted before normal noise')

print('Notification retention tests passed')

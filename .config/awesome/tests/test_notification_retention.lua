#!/usr/bin/env lua

local root = os.getenv('HOME') .. '/.config/awesome/'
local retention = dofile(root .. 'library/notification-retention.lua')

local function notification(urgency, priority, hints, app_name)
    return {
        urgency = urgency or 'normal',
        app_name = app_name,
        _private = {
            retention_priority = priority,
            freedesktop_hints = hints,
        },
    }
end

assert(retention.limit == 10, 'notification retention limit changed')
assert(retention.priority(notification()) == 0, 'normal priority must be 0')
assert(retention.priority(notification('critical')) == 2, 'critical priority must be 2')
assert(retention.priority(notification('critical', 0)) == 2, 'explicit priority demoted critical notification')
assert(retention.priority(notification('normal', 1)) == 1, 'explicit priority was ignored')
assert(retention.priority(notification('normal', nil, {
    ['x-awesome-retention-priority'] = 1,
})) == 1, 'D-Bus priority hint was ignored')
assert(retention.priority(notification('normal', nil, {
    ['x-awesome-retention-priority'] = 999,
})) == 1, 'D-Bus priority hint exceeded sender priority')
assert(retention.priority(notification('normal', nil, nil, 'blueman')) == -1,
    'ordinary Bluetooth notification is not low priority')
assert(retention.priority(notification('critical', nil, nil, 'blueman')) == 2,
    'critical Bluetooth notification lost critical priority')
assert(retention.priority({}) == 0, 'malformed notifications must use default priority')
assert(retention.eviction_index({}) == nil, 'empty history has no eviction candidate')

local bluetooth = notification('normal', nil, nil, 'blueman')
assert(retention.eviction_index({ notification(), notification(), bluetooth }) == 3,
    'Bluetooth notification was not selected before normal notifications')

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

local evicted_entries = {}
local store = retention.new(function(entry)
    evicted_entries[#evicted_entries + 1] = entry
end)
local before_add = os.time()
local critical_entry = store:add(critical)
local email_entry = store:add(email)
assert(type(critical_entry.created_at) == 'number', 'store omitted notification receipt time')
assert(critical_entry.created_at >= before_add and critical_entry.created_at <= os.time(),
    'store recorded an invalid notification receipt time')
local original_created_at = critical_entry.created_at
assert(store:add(critical) == critical_entry, 'duplicate notification created a new entry')
assert(critical_entry.created_at == original_created_at,
    'duplicate notification reset its original receipt time')
local primary_view = {}
local external_view = {}
local critical_card = {}
local external_card = {}
store:set_card(critical, primary_view, critical_card)
store:set_card(critical, external_view, external_card)

for _ = 1, 20 do
    store:add(notification())
end

assert(#store.entries == retention.limit, 'store exceeded notification limit')
assert(store:get(critical) == critical_entry, 'store evicted critical notification')
assert(store:get(email) == email_entry, 'store evicted sender-priority notification')
assert(store:get(critical).cards[primary_view] == critical_card, 'store lost notification card mapping')
assert(store:get(critical).cards[external_view] == external_card, 'store lost second view card mapping')
local removed_critical = store:remove(critical)
assert(removed_critical.cards[primary_view] == critical_card, 'store removal lost card mapping')
assert(removed_critical.cards[external_view] == external_card, 'store removal lost second view card mapping')
assert(store:get(critical) == nil, 'store retained removed notification')
assert(#evicted_entries == 12, 'store did not report every automatic eviction')

local protected_store = retention.new()
for _ = 1, retention.limit do
    protected_store:add(notification('critical'))
end
local rejected = notification()
local rejected_entry, rejected_eviction = protected_store:add(rejected)
assert(rejected_entry == nil, 'self-evicted notification remained in store')
assert(rejected_eviction.notification == rejected, 'store evicted a protected notification')
assert(#protected_store.entries == retention.limit, 'self-eviction changed store size')

local controller = assert(io.open(root .. 'module/notifications.lua', 'r'))
local controller_source = controller:read('*a')
controller:close()
assert(controller_source:match('pcall%(awful%.screen%.preferred%)'),
    'notifications lost preferred-screen fallback')
assert(controller_source:match('screen%.count%(%) > 1'),
    'notifications no longer detect an external screen')
assert(controller_source:match('candidate ~= screen%.primary'),
    'notifications no longer prefer the external screen')
assert(controller_source:match('screen%.primary or screen%[1%]'),
    'notifications no longer fall back to the primary screen')
assert(controller_source:match('view%.add_notification%(entry%.notification, entry%.created_at%)'),
    'notification cards no longer receive the original receipt time')

local view_source_file = assert(io.open(
    root .. 'widget/notif-center/build-notifbox/init.lua', 'r'))
local view_source = view_source_file:read('*a')
view_source_file:close()
assert(view_source:match('view%.add_notification = function%(n, created_at%)'),
    'notification view discarded the original receipt time')
assert(view_source:match('view,%s+created_at%s+%)'),
    'notification view did not pass receipt time to the card builder')

print('Notification retention tests passed')

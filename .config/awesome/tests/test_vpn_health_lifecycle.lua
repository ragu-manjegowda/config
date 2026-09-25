-- Test-only override of the read-only os.time function.
-- luacheck: ignore 122
local home = assert(os.getenv('HOME'))
local callbacks = {}
local health_events = {}
local notifications = 0
local now = 1000
local status_callback
local old_time = os.time
os.time = function() return now end

package.loaded.awful = {
    widget = {
        watch = function(_, _, callback)
            status_callback = callback
            return {}, { again = function() end }
        end,
    },
    spawn = {
        easy_async = function(argv, callback)
            callbacks[#callbacks + 1] = { argv = argv, callback = callback }
        end,
    },
}
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return home .. '/.config/awesome/' end },
    timer = function()
        return { again = function() end, stop = function() end }
    end,
}
package.loaded.wibox = {}
package.loaded.beautiful = { xresources = { apply_dpi = function(value) return value end } }
package.loaded.naughty = { notification = function() notifications = notifications + 1 end }
awesome = {
    emit_signal = function(name, value)
        if name == 'module::vpn_health' then health_events[#health_events + 1] = value end
    end,
}

local widget = dofile(home .. '/.config/awesome/widget/vpn/init.lua')
assert(type(widget) == 'function' and status_callback)
local function status(value) status_callback(nil, value .. '\n') end

status('connected')
assert(#callbacks == 1, 'first connection did not start health probe')
local old_probe = callbacks[1].callback
status('disconnected')
old_probe('', '', '', 0)
assert(#health_events == 0, 'late successful probe marked a disconnected VPN healthy')

status('connected')
assert(#callbacks == 2, 'new connection remained blocked by old in-flight probe')
old_probe('', '', '', 1)
assert(#health_events == 0, 'old failed probe affected the new connection')

for failure = 1, 3 do
    callbacks[#callbacks].callback('', '', '', 1)
    if failure < 3 then
        now = now + 60
        status('connected')
    end
end
assert(health_events[#health_events] == 'unhealthy')
assert(#callbacks == 5, 'three failures did not launch one diagnostic')
local old_diagnostics = callbacks[5].callback
status('disconnected')
old_diagnostics(home .. '/.local/state/prisma-access-agent/vpn-health.log\n')
assert(notifications == 0, 'late diagnostics notified after disconnect')

os.time = old_time
print('VPN health lifecycle tests passed')

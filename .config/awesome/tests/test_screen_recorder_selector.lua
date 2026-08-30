local home = assert(os.getenv("HOME"))
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" .. package.path

local command, process_callback
package.loaded.awful = {
    spawn = {
        easy_async = function(args, callback)
            command = args
            process_callback = callback
        end
    }
}
package.loaded.gears = {
    timer = { start_new = function(_, callback) callback() end }
}
package.loaded.beautiful = {
    accent = '#859900',
    xresources = { apply_dpi = function(value) return value end }
}
package.loaded["gears.filesystem"] = {}
package.loaded["widget.screen-recorder.screen-recorder-storage"] = {}
root = { size = function() return 2880, 1800 end }

local selector = require("widget.screen-recorder.screen-recorder-selector")
local hidden = false
local result, reason

selector.start(function()
    hidden = true
end, function(region, outcome)
    result, reason = region, outcome
end)

assert(hidden and selector.active, "selector must hide recorder overlays before starting")
assert(command[1] == "slop" and command[2] == "-t" and command[3] == "0",
    "selector must require a drag operation")
process_callback("10 20 801 603", "", "exit", 0)
assert(not selector.active and result.width == 800 and result.height == 602,
    "successful selection must return normalized geometry")

selector.start(function() end, function(region, outcome)
    result, reason = region, outcome
end)
process_callback("", "", "exit", 1)
assert(result == nil and reason == "cancelled",
    "right-click cancellation must preserve the previous selection")

selector.start(function() end, function(region, outcome)
    result, reason = region, outcome
end)
process_callback("0 0 4 4", "", "exit", 0)
assert(result == nil and reason == "invalid", "tiny selections must be rejected")

print("Screen recorder selector tests passed")

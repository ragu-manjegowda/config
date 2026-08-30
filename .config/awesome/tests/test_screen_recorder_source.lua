local home = assert(os.getenv("HOME"))
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" .. package.path

package.loaded["widget.screen-recorder.screen-recorder-storage"] = {
    read = function() return nil end,
    write = function() end
}
local external_screen = {
    valid = true,
    outputs = { ["DP-4"] = true },
    geometry = { x = 0, y = 0, width = 1920, height = 1080 }
}
screen = setmetatable({}, {
    __call = function(_, _, previous)
        if previous == nil then return external_screen end
        return nil
    end
})
root = { size = function() return 1920, 1080 end }

local config = {
    widget = { screen_recorder = { display_target = "external", audio = false } },
    display = {
        primary = { name = "eDP-1", mode = "2880x1800", position = "0x0" },
        external = { name = "DP-4", mode = "1920x1080", position = "0x0" }
    }
}
local controller = require("widget.screen-recorder.screen-recorder-source").new(config)
local geometry, err = controller:resolve()
assert(not err and geometry.width == 1920 and geometry.height == 1080,
    "external-only desktop must resolve the connected external output")

controller.state.source = "both"
geometry, err = controller:resolve()
assert(geometry == nil and err == "Primary display unavailable",
    "Both must require the configured primary output")

print("Screen recorder source tests passed")

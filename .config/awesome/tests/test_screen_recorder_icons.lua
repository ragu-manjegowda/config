local home = assert(os.getenv("HOME"))
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" .. package.path

package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return "/config/" end },
    color = {
        recolor_image = function(path, color)
            return { path = path, color = color }
        end
    }
}
package.loaded.beautiful = {
    fg_normal = "foreground",
    accent = "accent",
    bg_urgent = "urgent"
}

local icons = require("widget.screen-recorder.screen-recorder-icons")
local normal = icons.normal("settings")
local selected = icons.accent("recorder-countdown")
local recording = icons.urgent("recorder-on")

assert(normal.path:match("settings%.svg$") and normal.color == "foreground",
    "normal recorder icons must use the theme foreground")
assert(selected.color == "accent", "countdown icons must use the theme accent")
assert(recording.color == "urgent", "recording icons must use the theme urgent color")

print("Screen recorder icon tests passed")

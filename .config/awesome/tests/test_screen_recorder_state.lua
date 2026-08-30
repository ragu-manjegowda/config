local home = assert(os.getenv("HOME"))
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" .. package.path

package.loaded["gears.filesystem"] = {
    make_parent_directories = function(path)
        local parent = assert(path:match("^(.+)/[^/]+$"))
        assert(os.execute(string.format("mkdir -p %q", parent)))
    end
}
local stored
package.loaded["widget.screen-recorder.screen-recorder-storage"] = {
    read = function() return stored end,
    write = function(_, content) stored = content end
}

local recorder_state = require("widget.screen-recorder.screen-recorder-state")

local primary = {
    mode = "2880x1800",
    position = "0x0"
}
local external = {
    mode = "3840x2160",
    scale_from = "2880x1620",
    position = "2880x0"
}

local region = assert(recorder_state.parse_selection("101 51 801 603"))
assert(region.x == 101 and region.y == 51, "selection must preserve pointer offset")
assert(region.width == 800 and region.height == 602,
    "selection dimensions must normalize to even values")
assert(recorder_state.parse_selection("0 0 10 10") == nil,
    "selection smaller than the minimum must be rejected")
assert(recorder_state.parse_selection("-1 0 800 600") == nil,
    "negative X11 offsets must be rejected")
assert(recorder_state.parse_selection("0 0 3000 2000", 2880, 1800) == nil,
    "selection outside the X root must be rejected")
assert(recorder_state.parse_selection("0 0 " .. string.rep("9", 400) .. " 600") == nil,
    "overflowing numeric input must be rejected")
assert(recorder_state.parse_selection("cancelled") == nil,
    "invalid selector output must be rejected")

local state = recorder_state.default("external", true)
assert(state.audio == true, "default audio preference must be retained")
local geometry, err = recorder_state.resolve(state, primary, external, true)
assert(not err and geometry.width == 2880 and geometry.height == 1620,
    "external source must use its logical scaled geometry")
assert(geometry.x == 2880 and geometry.y == 0,
    "external source must use its configured offset")
geometry, err = recorder_state.resolve(state, { mode = "bad", position = "bad" },
    external, true, 5760, 1800)
assert(not err and geometry.x == 2880,
    "external-only capture must not require primary geometry")

state.source = "both"
geometry, err = recorder_state.resolve(state, primary, external, true)
assert(not err and geometry.width == 5760 and geometry.height == 1800,
    "both source must cover the complete display bounding box")

state.source = "external"
geometry, err = recorder_state.resolve(state, primary, external, false)
assert(geometry == nil and err == "External display unavailable",
    "unavailable external source must not silently fall back")

state.source = "primary"
geometry, err = recorder_state.resolve(state, {
    mode = "801x603", position = "-1x0"
}, external, false, 2880, 1800)
assert(geometry == nil and err == "Primary display geometry is outside the current desktop",
    "display geometry outside the X root must be rejected")
geometry, err = recorder_state.resolve(state, {
    mode = "801x603", position = "0x0"
}, external, false, 2880, 1800)
assert(not err and geometry.width == 800 and geometry.height == 602,
    "display geometry must normalize to H.264-compatible dimensions")

state.source = "region"
state.region = region
geometry, err = recorder_state.resolve(state, primary, external, false)
assert(not err and geometry.x == region.x and geometry.width == region.width,
    "custom region must resolve without an external display")
state.region = { x = 2800, y = 1700, width = 800, height = 600 }
geometry, err = recorder_state.resolve(state, primary, external, false, 2880, 1800)
assert(geometry == nil and err == "Saved area is outside the current desktop",
    "persisted regions outside the current root must be rejected")
state.region = region

local path = "/state/settings"
recorder_state.save(path, state)
local restored = recorder_state.load(path, "primary", false)
assert(restored.source == "region", "saved capture source must survive reload")
assert(restored.region and restored.region.x == 101 and restored.region.width == 800,
    "saved custom region must survive reload")
assert(restored.audio == true, "saved audio preference must survive reload")
local video_size, input = recorder_state.ffmpeg_geometry(restored.region)
assert(video_size == "800x602" and input == ":0.0+101,51",
    "validated geometry must produce x11grab arguments")
assert(recorder_state.summary(restored.region) == "800x602 at 101,51",
    "validated geometry must produce a readable summary")
os.remove(path)

print("Screen recorder state tests passed")

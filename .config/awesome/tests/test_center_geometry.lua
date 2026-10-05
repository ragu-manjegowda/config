-- Screen-relative sizing and existing section viewports, with no X11/hardware.
local config_dir = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = config_dir .. '?.lua;' .. package.path
local function object(properties)
    local value = properties or {}
    value.handlers = {}
    function value:connect_signal(name, callback) self.handlers[name] = callback end

    function value:disconnect_signal(name, callback)
        if self.handlers[name] == callback then self.handlers[name] = nil end
    end

    function value:emit_signal(name, ...) if self.handlers[name] then self.handlers[name](self, ...) end end

    return value
end
package.loaded['wibox.widget.base'] = {
    fit_widget = function(_, _, child, width)
        return width, child.header + child:get_viewport_height()
    end
}
package.loaded.beautiful = {
    useless_gap = 8,
    xresources = {
        apply_dpi = function(value, s) return value * s.dpi / 96 end,
        get_dpi = function(s) return s.dpi end,
    }
}
local removed_handlers = {}
screen = {
    connect_signal = function(_, handler) removed_handlers[#removed_handlers + 1] = handler end,
    disconnect_signal = function() end,
}
local geometry = require('layout.center-geometry')
local function make_screen(x, y, width, height, scale)
    local bar = 46 * scale / 96
    return object {
        valid = true, dpi = scale,
        geometry = { x = x, y = y, width = width, height = height },
        workarea = { x = x, y = y + bar, width = width, height = height - bar },
    }
end
local primary = make_screen(0, 0, 2880, 1800, 144)
local external = make_screen(2880, 0, 3440, 1440, 144)
local small = make_screen(-1920, 200, 1920, 1080, 96)
assert(geometry.width(primary) == 720 and geometry.width(external) == 860,
    'The original screen-relative width fraction must remain intact')
assert(geometry.width(small) == 320)
for _, s in ipairs { primary, external, small } do
    local bounds = geometry.bounds(s)
    assert(bounds.y >= s.workarea.y and bounds.y + bounds.height <= s.workarea.y + s.workarea.height,
        'Screen pixel height must not get multiplied by DPI again')
end
assert(geometry.bounds(external).height == 1339)
local contents = {}
local panel = object { widget = contents, height = 2000, visible = false }
geometry.bind(panel, external, 'top_right')
assert(panel.height == 1339 and panel.maximum_height == 1339)
assert(panel.x == 5444 and panel.y == 85 and panel.width == 860)
assert(geometry.bounds(primary).y == panel.y,
    'Different screen heights must not change client/notification top-edge alignment')
assert(panel.y == external.workarea.y + 2 * package.loaded.beautiful.useless_gap,
    'Center top edge must match the tiled-client outer gap')
assert(panel.widget == contents, 'Sizing must not replace the layout with a scrolling wrapper')

local sections = {}
for i = 1, 5 do
    local section = { header = 60, limit = 232, content = 500 }
    function section:get_viewport_height() return math.min(self.content, self.limit) end

    function section:set_viewport_height(height) self.limit = math.min(232, height) end

    sections[i] = section
end
geometry.fit_sections(panel, external, sections)
local total = 48 + 60 -- Existing outer margin and four inter-section gaps.
for _, section in ipairs(sections) do
    assert(section.limit > 0 and section.limit < 232, 'Short screen must reduce its existing list viewports')
    assert(section.content == 500, 'Responsive sizing must not discard list entries')
    total = total + section.header + section:get_viewport_height()
end
assert(total <= panel.maximum_height + 0.000001, 'The original sections must all fit inside the panel')
sections[1].get_minimum_viewport_height = function() return 216.5 end
sections[2].get_minimum_viewport_height = function() return 132 end
geometry.fit_sections(panel, external, sections)
assert(sections[1].limit >= 217 and sections[2].limit >= 132,
    'Available space must prioritize a complete notification and email card')
total = 48 + 60
for _, section in ipairs(sections) do total = total + section.header + section:get_viewport_height() end
assert(total <= panel.maximum_height, 'Full-card reservation must not enlarge the panel beyond the screen')
local large_panel = { widget = contents, width = 720, maximum_height = geometry.bounds(primary).height }
geometry.fit_sections(large_panel, primary, sections)
for _, section in ipairs(sections) do assert(section.limit == 232, 'Larger screen must restore the original list limits') end

external.geometry = { x = -3440, y = 300, width = 3440, height = 1080 }
external.workarea = { x = -3440, y = 369, width = 3440, height = 1011 }
external:emit_signal('property::geometry')
assert(panel.maximum_height == 979 and panel.y == 385 and panel.x == -876,
    'Resize/reposition must use the owning screen geometry')
local centered = object { widget = contents, height = 100 }
geometry.bind(centered, small, 'top')
assert(centered.x == -1120 and centered.y == 262)
small.workarea = small.geometry
small:emit_signal('property::workarea')
assert(centered.y == small.geometry.y + 16,
    'A hidden top panel must align centers with the screen-edge client/notification gap')
for _, callback in ipairs(removed_handlers) do callback(external) end
assert(external.handlers['property::geometry'] == nil)
print('screen-relative center and existing section sizing tests passed')

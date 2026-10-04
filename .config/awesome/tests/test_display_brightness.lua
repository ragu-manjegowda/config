-- Load the real queue and controls with deferred hardware replies.
local root = os.getenv('HOME') .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local focused
local primary = { valid = true, outputs = { ['eDP-1'] = true }, geometry = { width = 1000, height = 700 } }
local external = { valid = true, outputs = { ['DP-1-1'] = true }, geometry = { width = 1000, height = 700 } }
focused = external
local calls, timers, signals, events, nodes = {}, {}, {}, {}, {}
_G.awesome = {
    connect_signal = function(name, fn)
        signals[name] = signals[name] or {}
        table.insert(signals[name], fn)
    end,
    emit_signal = function(name, ...)
        events[#events + 1] = { name, ... }
        for _, fn in ipairs(signals[name] or {}) do fn(...) end
    end,
}
local function node(spec)
    if spec and spec.handlers then return spec end
    local n = { handlers = {}, value = 0 }
    for k, v in pairs(spec or {}) do
        n[k] = type(k) == 'number' and type(v) == 'table' and node(v) or v
    end
    function n:connect_signal(name, fn) self.handlers[name] = fn end
    function n:buttons() end
    function n:add_to_object() end
    function n:setup() end
    function n:get_value() return self.value end
    function n:set_value(value)
        if self.value == value then return end
        self.value = value
        if self.handlers['property::value'] then self.handlers['property::value']() end
    end
    local function visit(value)
        if type(value) ~= 'table' then return end
        if value.id then
            n[value.id] = value
            nodes[value.id] = value
            return
        end
        for index, child in pairs(value) do if type(index) == 'number' then visit(child) end end
    end
    for index, child in pairs(n) do if type(index) == 'number' then visit(child) end end
    return n
end
local wibox = { widget = setmetatable({}, { __call = function(_, spec) return node(spec) end }),
    layout = { align = {}, fixed = {} }, container = { background = function() end } }
package.loaded.wibox = wibox
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return root end }, shape = {},
    debug = { print_warning = function() end },
    timer = function(spec)
        local timer = spec
        function timer:again() self.started = true end
        timer.start = timer.again
        function timer:stop() self.started = false end
        timers[#timers + 1] = timer
        return timer
    end,
}
package.loaded.awful = {
    screen = { focused = function() return focused end },
    spawn = { easy_async = function(argv, callback) calls[#calls + 1] = { argv = argv, callback = callback } end },
    tooltip = function() return node() end, popup = function(spec) return node(spec) end,
    placement = { bottom = function() end },
    button = function() end, util = { table = { join = function() end } },
}
package.loaded.beautiful = { xresources = { apply_dpi = function(n) return n end },
    font_bold = function() return '' end, groups_bg = '#000000' }
package.loaded['theme.icons'] = {}
package.loaded['widget.clickable-container'] = {}
package.loaded['widget.slider-hover'] = { attach = function() end }
package.loaded['configuration.config'] = { display = { primary = { name = 'eDP-1' } } }
local decorations = {}
_G.screen = { connect_signal = function(_, fn) decorations[#decorations + 1] = fn end }
local brightness = require('library.display-brightness')
local function flush() timers[1].started = false; timers[1].callback() end
local function reply(index, value, code) calls[index].callback(tostring(value), '', 'exit', code or 0) end

brightness.adjust(-10)
brightness.adjust(-10)
focused = primary
flush()
assert(calls[1].argv[3] == 'DP-1-1' and calls[1].argv[4] == '-U' and calls[1].argv[5] == '20')
brightness.set('eDP-1', 25)
brightness.set('eDP-1', 35)
brightness.set('DP-1-1', 45)
flush()
assert(#calls == 1, 'no overlapping slow writes')
reply(1, 55)
assert(events[1][3] == 'DP-1-1')
assert(#events == 1, 'old-screen completion must not show an OSD on another screen')
flush()
assert(calls[2].argv[3] == 'eDP-1' and calls[2].argv[5] == '35')
reply(2, 35)
flush()
assert(calls[3].argv[3] == 'DP-1-1' and calls[3].argv[5] == '45')
reply(3, 45)

require('widget.brightness-slider')
require('module.brightness-osd')
for _, callback in ipairs(decorations) do callback(primary); callback(external) end
local slider = assert(nodes.brightness_slider)
local osd = assert(nodes.bri_osd_slider)
reply(4, 35)
assert(slider.value == 35 and not timers[1].started, 'readback never causes writes')
focused = external
awesome.emit_signal('control_center::visibility', true)
local old_read = #calls
slider:set_value(60)
reply(old_read, 45)
assert(slider.value == 60, 'late hardware read cannot overwrite a newer drag')
assert(osd.value == 60, 'focused monitor value propagates to OSD')
flush()
assert(calls[#calls].argv[3] == 'DP-1-1')
reply(#calls, 60)
assert(external.brightness_osd_overlay.visible)
focused = primary
awesome.emit_signal('widget::brightness', false)
reply(#calls, 35)
assert(slider.value == 35 and osd.value == 35)
awesome.emit_signal('module::brightness_osd:show', true)
assert(not external.brightness_osd_overlay.visible and primary.brightness_osd_overlay.visible)
focused = external
timers[2].callback()
assert(not primary.brightness_osd_overlay.visible, 'expiry hides its original screen, not the new focus')
awesome.emit_signal('widget::brightness:changed', 99, 'eDP-1')
assert(slider.value == 35, 'other-screen success cannot overwrite focused slider')
osd:set_value(65)
flush()
assert(calls[#calls].argv[3] == 'DP-1-1', 'OSD drag uses the focused hardware backend')
reply(#calls, 65)
print('focused-screen brightness queue, controls and OSD tests passed')

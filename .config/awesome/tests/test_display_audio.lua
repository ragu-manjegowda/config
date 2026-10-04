-- Real audio queue, widgets and OSDs; hardware replies are fully deferred.
local root = os.getenv('HOME') .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local primary = { valid = true, outputs = { ['eDP-1'] = true }, geometry = { width = 1000, height = 700 } }
local external = { valid = true, outputs = { ['DP-1-1'] = true }, geometry = { width = 1000, height = 700 } }
local focused = external
local calls, timers, signals, events, nodes, decorations = {}, {}, {}, {}, {}, {}
awesome = {
    connect_signal = function(name, fn)
        signals[name] = signals[name] or {}; table.insert(signals[name], fn)
    end,
    emit_signal = function(name, ...)
        events[#events + 1] = { name, ... }
        for _, fn in ipairs(signals[name] or {}) do fn(...) end
    end,
}
local function node(spec)
    if spec and spec.handlers then return spec end
    local n = { handlers = {}, value = 0, valid = true, children = {} }
    for k, v in pairs(spec or {}) do
        n[k] = type(k) == 'number' and type(v) == 'table' and node(v) or v
        if type(k) == 'number' then n.children[#n.children + 1] = n[k] end
    end
    function n:connect_signal(name, fn) self.handlers[name] = fn end

    function n:buttons(value) self.bindings = value end

    function n:add_to_object() end

    function n:setup() end

    function n:set_text(value) self.text = value end

    function n:set_image(value) self.image = value end

    function n:get_value() return self.value end

    function n:set_value(value)
        if value == self.value then return end
        self.value = value
        if self.handlers['property::value'] then self.handlers['property::value']() end
    end

    local function visit(value)
        if type(value) ~= 'table' then return end
        if value.id then
            n[value.id] = value; nodes[value.id] = value
        end
        for index, child in pairs(value) do if type(index) == 'number' then visit(child) end end
    end
    for index, child in pairs(n) do if type(index) == 'number' then visit(child) end end
    return n
end
package.loaded.wibox = {
    widget = setmetatable({}, { __call = function(_, spec) return node(spec) end }),
    layout = { align = {}, fixed = {} },
    container = { background = function() end }
}

package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return root end },
    shape = {},
    debug = { print_warning = function() end },
    table = { join = function(...) return { ... } end },
    timer = function(spec)
        function spec:again() self.started = true end

        spec.start = spec.again
        function spec:stop() self.started = false end

        timers[#timers + 1] = spec; return spec
    end,
}

package.loaded.awful = {
    screen = { focused = function() return focused end },
    spawn = { easy_async = function(argv, callback) calls[#calls + 1] = { argv = argv, callback = callback } end },
    tooltip = function() return node() end,
    popup = function(spec) return node(spec) end,
    placement = { bottom = function() end },
    button = function(_, _, _, fn) return { fn = fn } end,
    util = { table = { join = function(...) return { ... } end } },
}

package.loaded.beautiful = {
    xresources = { apply_dpi = function(n) return n end },
    font_bold = function() return '' end,
    font_regular = function() return '' end,
    groups_bg = '#000000',
    fg_focus = '#ffffff',
    background_light = '#111111'
}
package.loaded['theme.icons'] = {
    volume = 'volume',
    volume_muted = 'muted',
    microphone_high = 'mic',
    microphone_muted = 'mic-muted'
}

package.loaded['widget.clickable-container'] = {}
package.loaded['widget.slider-hover'] = { attach = function() end }
package.loaded['library.display-brightness'] = {
    output = function(s)
        return (s or focused).outputs['eDP-1'] and 'eDP-1' or 'DP-1-1'
    end
}

package.loaded['configuration.config'] = {
    display = { primary = { name = 'eDP-1' } },
    widget = { audio = { primary_device_pattern = 'internal-card', external_device_pattern = 'usb-Monitor-*' } }
}

package.loaded['library.audio-monitor'] = { connect_signal = function() end }
screen = { connect_signal = function(_, fn) decorations[#decorations + 1] = fn end }
local audio = require('library.display-audio')
local json = require('library.json')
local function flush()
    timers[1].started = false; timers[1].callback()
end
local function reply(index, state, code) calls[index].callback(json.stringify(state), '', 'exit', code or 0) end
local function state(volume, muted) return { available = true, volume = volume, muted = muted, description = 'fixture' } end

audio.adjust(-5); audio.adjust(-5)
focused = primary
flush()
assert(calls[1].argv[6] == 'external' and calls[1].argv[14] == '-10', 'gesture target was not captured/coalesced')
audio.set('eDP-1', 40)
flush(); assert(#calls == 1, 'writes overlap')
reply(1, state(70, false)); flush()
assert(calls[2].argv[6] == 'primary')
reply(2, state(40, false))

require('widget.volume-slider')
local microphone = require('widget.microphone-toggle')
require('module.volume-osd'); require('module.mic-osd')
for _, decorate in ipairs(decorations) do
    decorate(primary); decorate(external)
end
reply(3, state(34, true)); reply(4, state(100, false))
local slider, osd = assert(nodes.volume_slider), assert(nodes.vol_osd_slider)
assert(slider.value == 34 and not timers[1].started, 'status refresh issued hardware write')
focused = external
awesome.emit_signal('control_center::visibility', true)
local old_read = #calls - 1
slider:set_value(60)
reply(old_read, state(80, false))
assert(slider.value == 60, 'late read overwrote a newer drag')
reply(#calls, { available = false })
microphone[1].bindings[1].fn()
flush()
assert(calls[#calls].argv[6] == 'external', 'monitor gesture changed the default/laptop endpoint')
reply(#calls, state(60, false)); flush()
assert(calls[#calls].argv[4] == 'source' and calls[#calls].argv[12] == 'mute')
reply(#calls, state(100, true))
assert(external.mic_osd_overlay.visible)
focused = primary
timers[3].callback()
assert(not external.mic_osd_overlay.visible, 'microphone expiry hid wrong screen')
focused = external
awesome.emit_signal('module::volume_osd:show', true)
focused = primary
timers[2].callback()
assert(not external.volume_osd_overlay.visible, 'volume expiry hid wrong screen')
focused = external
awesome.emit_signal('module::volume_osd:show', true)
osd:set_value(45); flush()
assert(calls[#calls].argv[6] == 'external', 'OSD drag lost its original device')
reply(#calls, { available = false }, 1)
assert(slider.value == 0, 'unavailable monitor was represented as a working volume control')
print('focused audio queue, widget, unavailable-state and OSD tests passed')

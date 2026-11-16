-- Real audio queue, widgets and OSDs; hardware replies are fully deferred.
local root = os.getenv('HOME') .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local primary = { valid = true, outputs = { ['eDP-1'] = true }, geometry = { width = 1000, height = 700 } }
local external = { valid = true, outputs = { ['DP-1-1'] = true }, geometry = { width = 1000, height = 700 } }
local focused = external
local calls, timers, signals, events, nodes, decorations = {}, {}, {}, {}, {}, {}
local textboxes, tooltips = {}, {}
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
    if n.text ~= nil then textboxes[#textboxes + 1] = n end
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

local function make_timer(spec)
    function spec:again() self.started = true end

    spec.start = spec.again
    function spec:stop() self.started = false end

    timers[#timers + 1] = spec
    return spec
end
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return root end },
    shape = {},
    debug = { print_warning = function() end },
    table = { join = function(...) return { ... } end },
    timer = setmetatable({
        start_new = function(timeout, callback)
            return make_timer { timeout = timeout, callback = callback, started = true }
        end
    }, { __call = function(_, spec) return make_timer(spec) end }),
}

package.loaded.awful = {
    screen = { focused = function() return focused end },
    spawn = { easy_async = function(argv, callback) calls[#calls + 1] = { argv = argv, callback = callback } end },
    tooltip = function(spec)
        local tooltip = node(spec)
        tooltips[#tooltips + 1] = tooltip
        return tooltip
    end,
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
    display = { primary = { name = 'eDP-1' }, external = { name = 'DP-1-1' } },
    widget = { audio = { primary_device_pattern = 'internal-card', external_device_pattern = 'usb-Monitor-*' } }
}

local audio_signals = {}
package.loaded['library.audio-monitor'] = {
    connect_signal = function(_, name, callback)
        local previous = audio_signals[name]
        audio_signals[name] = function(...)
            if previous then previous(...) end
            callback(...)
        end
    end,
}
screen = { connect_signal = function(_, fn) decorations[#decorations + 1] = fn end }
local audio = require('library.display-audio')
local startup_recovery = timers[#timers]
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

local volume_widget = require('widget.volume-slider')
local volume_tooltip = tooltips[#tooltips]
local microphone = require('widget.microphone-toggle')
require('module.volume-osd')
local volume_text = textboxes[#textboxes]
assert(volume_text.text == '0%')
require('module.mic-osd')
local volume_osd_timer, mic_osd_timer = timers[#timers - 1], timers[#timers]
for _, decorate in ipairs(decorations) do
    decorate(primary); decorate(external)
end
reply(3, state(34, true)); reply(4, state(100, false))
local slider, osd = assert(nodes.volume_slider), assert(nodes.vol_osd_slider)
assert(slider.value == 34 and not timers[1].started, 'status refresh issued hardware write')
for _, fixture in ipairs({
    { 0, '0%' }, { 34.499, '34%' }, { 34.5, '35%' },
    { 34.9993896484375, '35%' }, { 99.999, '100%' }, { 100, '100%' },
}) do
    awesome.emit_signal('widget::audio:changed', 'eDP-1', 'sink', state(fixture[1], false))
    assert(volume_text.text == fixture[2] and volume_tooltip.text == 'Volume value = ' .. fixture[2],
        'Readback fractions must display as the same rounded percentage in the OSD and tooltip')
    assert(slider.value == fixture[1] and not timers[1].started,
        'Formatting must preserve raw volume precision and must not write to hardware')
end
awesome.emit_signal('widget::audio:changed', 'eDP-1', 'sink', state(34, true))
assert(volume_tooltip.text == 'Volume value = 34% (muted)')
volume_widget.handlers['mouse::enter']()
reply(#calls, state(51.999, false))
assert(volume_tooltip.text == 'Volume value = 52%' and volume_text.text == '52%',
    'A hover query must update the tooltip when its asynchronous reply arrives')
awesome.emit_signal('widget::volume:update', 66.6, 'eDP-1')
assert(volume_tooltip.text == 'Volume value = 67%' and not timers[1].started,
    'OSD-origin slider synchronization must refresh the tooltip without a second hardware write')
awesome.emit_signal('widget::audio:changed', 'eDP-1', 'sink', state(34, true))
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
mic_osd_timer.callback()
assert(not external.mic_osd_overlay.visible, 'microphone expiry hid wrong screen')
focused = external
awesome.emit_signal('module::volume_osd:show', true)
focused = primary
volume_osd_timer.callback()
assert(not external.volume_osd_overlay.visible, 'volume expiry hid wrong screen')
focused = external
awesome.emit_signal('module::volume_osd:show', true)
osd:set_value(45); flush()
assert(calls[#calls].argv[6] == 'external', 'OSD drag lost its original device')
reply(#calls, { available = false }, 1)
assert(slider.value == 0, 'unavailable monitor was represented as a working volume control')
assert(volume_tooltip.text == 'Audio device unavailable', 'An absent device must not show a stale percentage')

focused = primary
awesome.emit_signal('module::sleep_resumed')
local recovery = timers[#timers]
local refresh_calls = #calls
assert(recovery.timeout == 1 and recovery.started)
assert(recovery.callback())
flush()
assert(#calls == refresh_calls + 1 and calls[#calls].argv[6] == 'external'
    and calls[#calls].argv[12] == 'resync', 'Resume must reconcile the monitor, not the focused laptop mic')
reply(#calls, { available = false }, 1)
assert(recovery.started, 'Missing USB source must be retried')
recovery.callback(); flush()
local osd_events = #events
reply(#calls, state(100, false))
assert(not recovery.started, 'Successful recovery must stop its retry timer')
for index = osd_events + 1, #events do
    assert(events[index][1] ~= 'module::mic_osd:show', 'Resume recovery must not display an OSD')
end

awesome.emit_signal('module::sleep_resumed')
local abandoned = timers[#timers]
awesome.emit_signal('module::sleep_resumed')
assert(not abandoned.started and not abandoned.callback(), 'A newer resume must retire the old retry')
recovery = timers[#timers]
for attempt = 1, 10 do
    assert(recovery.callback() == (attempt < 10), 'Missing-device retries must be bounded')
    flush(); reply(#calls, { available = false }, 1)
end
local function complete_recovery_probe(index, probe_call)
    local selected = state(100, false)
    selected.index = index
    reply(probe_call or #calls, selected)
    local retry = timers[#timers]
    assert(retry.timeout == 1 and retry.started)
    retry.callback(); flush()
    assert(calls[#calls].argv[6] == 'external' and calls[#calls].argv[12] == 'resync')
    reply(#calls, selected)
    assert(not retry.started)
end

for _, trigger in ipairs({ 'module::display_woke', 'module::unlocked' }) do
    local probe_call = #calls + 1
    awesome.emit_signal(trigger)
    complete_recovery_probe(283, probe_call)
end
assert(startup_recovery.timeout == 3 and not startup_recovery.callback())
complete_recovery_probe(283)

local before_timers = #timers
audio_signals.source(nil, 'change', 283)
audio_signals.source(nil, 'remove', 283)
assert(#timers == before_timers and not timers[1].started,
    'Mute-change events must not start a feedback loop or removal recovery')
audio_signals.source(nil, 'new', 283)
assert(not timers[#timers].callback())
complete_recovery_probe(283)

audio_signals.source(nil, 'new', 999)
assert(not timers[#timers].callback())
local unmatched_timers = #timers
local selected = state(100, false)
selected.index = 283
reply(#calls, selected)
assert(#timers == unmatched_timers and not timers[1].started,
    'An unrelated new source must not cause a monitor mute transition')
awesome.emit_signal('module::display_woke')
reply(#calls, { available = false })
assert(#timers == unmatched_timers, 'Wake without a monitor must not start needless retries')
print('focused audio queue, wake/startup/hotplug recovery, widget and OSD tests passed')

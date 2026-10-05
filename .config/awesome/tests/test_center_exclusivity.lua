local config_dir = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = config_dir .. '?.lua;' .. config_dir .. '?/init.lua;' .. package.path

local suspension_state = false
local transitions = {}
package.preload['library.machine'] = function()
    return { battery = true, power_profile = true, keyboard_backlight = true }
end
package.preload['library.notification-suspension'] = function()
    return { set = function(_, active) suspension_state = active end }
end

local function widget(args)
    local value = args or {}
    if value.visible == nil then value.visible = false end
    function value:buttons(buttons) self.clicks = buttons end

    function value:emit_signal(name)
        if self.test_name and (name == 'opened' or name == 'closed') then
            transitions[#transitions + 1] = self.test_name .. ':' .. name
        end
    end

    function value:connect_signal() end

    function value:get_children_by_id()
        return { { visible = false } }
    end

    return value
end

local widget_types = setmetatable({
    textclock = function() return widget() end,
    separator = {},
}, { __call = function(_, args) return widget(args) end })
local wibox = setmetatable({
    widget = widget_types,
    layout = { align = {}, fixed = {}, flex = {}, stack = {} },
    container = { margin = {}, background = {} },
}, { __call = function(_, args) return widget(args) end })
package.preload.wibox = function() return wibox end

local focused
package.preload.awful = function()
    return {
        popup = function(args)
            args.widget = widget(args.widget)
            return widget(args)
        end,
        placement = { top = function() end, top_right = function() end },
        screen = { focused = function() return focused end },
        button = function(_, _, _, callback) return callback end,
        util = { table = { join = function(...) return { ... } end } },
    }
end
package.preload.gears = function() return { shape = {} } end
package.preload.beautiful = function()
    return {
        font_bold = function() return 'mock-font' end,
        xresources = { apply_dpi = function(value) return value end }
    }
end

local calendar_updates = 0
local calendar = setmetatable({ update = function() calendar_updates = calendar_updates + 1 end }, {
    __call = function() return widget() end,
})
package.preload['widget.calendar'] = function() return calendar end
for _, name in ipairs({
    'user-profile', 'control-center-switch', 'end-session', 'airplane-mode',
    'bluetooth-toggle', 'blue-light', 'microphone-toggle', 'dont-disturb',
    'blur-toggle', 'presentation-mode', 'power-profile', 'blur-slider',
    'brightness-slider', 'volume-slider', 'kbd-brightness-slider', 'cpu-meter',
    'ram-meter', 'temperature-meter', 'harddrive-meter', 'notif-center',
    'email', 'stocks', 'calendar-events', 'weather', 'playerctl',
}) do
    package.preload['widget.' .. name] = function()
        return function() return widget() end
    end
end

local removed_handlers = {}
screen = {
    connect_signal = function(name, handler)
        if name == 'removed' then removed_handlers[#removed_handlers + 1] = handler end
    end,
    disconnect_signal = function() end,
}
awesome = { emit_signal = function() end }

local names = { 'control_center', 'info_center', 'calendar_center', 'playerctl_center' }
local constructors = {}
for _, name in ipairs(names) do
    constructors[name] = require('layout.' .. name:gsub('_', '-'))
end
local manager = require('layout.center-manager')

local function make_screen(x)
    local s = {
        geometry = { x = x, y = 0, width = 1200, height = 800 },
        top_panel = { visible = true, height = 45 }
    }
    focused = s
    for _, name in ipairs(names) do
        s[name] = constructors[name](s)
        s[name].test_name = name
    end
    return s
end

local first = make_screen(0)
local second = make_screen(1200)
local function check(panel, name, s, open)
    assert(panel.visible == open and panel.opened == open,
        name .. ' visible/opened state is inconsistent')
    assert(s['backdrop_' .. name].visible == open,
        name .. ' click-outside backdrop is inconsistent')
end

for _, source_name in ipairs(names) do
    for _, target_name in ipairs(names) do
        manager.hide()
        focused = first
        first[source_name]:toggle()
        check(first[source_name], source_name, first, true)
        assert(manager.active() == first[source_name])
        if source_name ~= target_name then
            first[target_name]:toggle()
            check(first[source_name], source_name, first, false)
            check(first[target_name], target_name, first, true)
            assert(manager.active() == first[target_name])
        end
        manager.hide()
        check(first[target_name], target_name, first, false)
        assert(manager.active() == nil and not suspension_state)
        -- A panel closed by another panel must open on the first click again.
        first[source_name]:toggle()
        check(first[source_name], source_name, first, true)
        manager.hide()
    end
end

first.control_center:toggle()
transitions = {}
first.info_center:toggle()
assert(table.concat(transitions, ',') == 'control_center:closed,info_center:opened',
    'Control Center must close before Info Center opens')
manager.hide()

first.info_center:toggle()
assert(suspension_state, 'open Info Center must suspend notification popups')
first.control_center:toggle()
assert(not suspension_state, 'switching away must resume notification popups')
first.backdrop_control_center.clicks[1]()
check(first.control_center, 'control_center', first, false)
assert(manager.active() == nil, 'outside click must release the active panel')

first.control_center:toggle()
focused = second
second.info_center:toggle()
check(first.control_center, 'control_center', first, false)
check(second.info_center, 'info_center', second, true)
manager.hide()
check(second.info_center, 'info_center', second, false)
assert(calendar_updates > 0, 'calendar must refresh when opened')

local tag_handler
package.preload['layout.top-panel'] = function()
    return function(s) return s.top_panel end
end
tag = { connect_signal = function(_, callback) tag_handler = callback end }
client = { connect_signal = function() end }
setmetatable(screen, {
    __call = function(_, _, previous)
        if not previous then return first end
        if previous == first then return second end
    end
})
require('layout.init')

first.selected_tag = { clients = function() return {} end }
focused = first
first.control_center:toggle()
first.selected_tag.clients = function() return { { fullscreen = true } } end
tag_handler()
check(first.control_center, 'control_center', first, false)
assert(first.control_center_show_again and not first.top_panel.visible)
first.selected_tag.clients = function() return {} end
tag_handler()
check(first.control_center, 'control_center', first, true)
assert(not first.control_center_show_again and first.top_panel.visible,
    'full-screen exit must restore the previously open panel')
manager.hide()

first.control_center:toggle()
first.selected_tag.clients = function() return { { fullscreen = true } } end
tag_handler()
focused = second
second.info_center:toggle()
first.selected_tag.clients = function() return {} end
tag_handler()
check(first.control_center, 'control_center', first, false)
check(second.info_center, 'info_center', second, true)
assert(not first.control_center_show_again,
    'full-screen exit must not reopen a panel over the chosen center')
manager.hide()

first.control_center:toggle()
for _, callback in ipairs(removed_handlers) do callback(first) end
check(first.control_center, 'control_center', first, false)
assert(manager.active() == nil, 'removed screen retained an active center')

print('center exclusivity tests passed')

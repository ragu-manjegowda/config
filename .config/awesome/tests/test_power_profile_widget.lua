local config_dir = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = config_dir .. '?.lua;' .. config_dir .. '?/init.lua;' .. package.path

local function dpi(value) return value * 2 end
local theme = { xresources = { apply_dpi = dpi }, font_bold = tostring }
package.loaded.beautiful = theme
local bindings = require('theme.bindings')
local function apply_palette(name)
    for _, role in ipairs({
        'background', 'accent', 'background_light', 'system_green_light', 'system_yellow_light',
        'system_red_light', 'tooltip_bg', 'tooltip_fg', 'tooltip_border_color',
    }) do
        theme[role] = name .. ':' .. role
    end
    bindings.refresh()
end

local function make_widget(_, spec)
    local view = type(spec.widget) == 'function' and spec.widget() or {}
    for key, value in pairs(spec) do view[key] = value end
    view.add = table.insert
    function view:buttons(action) self.click = action end

    return view
end
package.loaded.wibox = {
    widget = setmetatable({}, { __call = make_widget }),
    layout = { flex = {}, fixed = {} },
    container = { background = function() return {} end },
}
package.loaded['widget.clickable-container'] = {}
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return config_dir end },
    shape = {},
    table = { join = function(action) return action end },
}
local signals, tooltips = {}, {}
awesome = {
    connect_signal = function(name, callback) signals[name] = callback end,
    emit_signal = function(name, ...) if signals[name] then signals[name](...) end end,
}
local current = 'balanced'
package.loaded.awful = {
    button = function(_, number, _, on_release)
        assert(number == 1, 'Profiles must respond to left click')
        return on_release
    end,
    tooltip = function(spec)
        spec.backgroundbox = {}
        tooltips[spec.objects[1]] = spec
        return spec
    end,
    spawn = {
        easy_async = function(argv, reply)
            assert(argv[2] == config_dir .. 'utilities/power/power-profile')
            if argv[3] == 'set' then current = assert(argv[4]) else assert(argv[3] == 'get') end
            reply(current .. '\n', '', 'exit', 0)
        end
    },
}
local profiles = {
    Performance = {
        key = 'performance',
        role = 'system_green_light',
        tooltip = '100% brightness · keep Bluetooth state · CPU performance · turbo on'
    },
    Balanced = {
        key = 'balanced',
        role = 'system_yellow_light',
        tooltip = '60% brightness · keep Bluetooth state · balanced CPU policy'
    },
    ['Power Saver'] = {
        key = 'power-saver',
        role = 'system_red_light',
        tooltip = '35% brightness · Bluetooth off · CPU power policy · turbo off'
    },
}
local function find_label(view)
    if view.text then return view end
    for _, child in ipairs(view) do
        local label = find_label(child)
        if label then return label end
    end
end
apply_palette('light')
require('widget.power-profile')
local buttons = {}
for button, tip in pairs(tooltips) do
    local label = assert(find_label(button), 'Profile button is missing its label')
    local profile = assert(profiles[label.text], 'Unexpected profile: ' .. label.text)
    assert(label.forced_width == dpi(118) and button.forced_height == dpi(40), label.text .. ' sizing')
    assert(tip.text == profile.tooltip, label.text .. ' tooltip text')
    buttons[profile.key] = button
end
local function check_selection(active)
    for label, profile in pairs(profiles) do
        local button = assert(buttons[profile.key], 'Missing profile button: ' .. label)
        local selected = profile.key == active
        assert(button.bg == (selected and theme.accent or theme.background), label .. ' background')
        assert(button.fg == (selected and theme.background or theme[profile.role]), label .. ' foreground')
        assert(button.shape_border_color == (selected and theme.accent or theme.background_light), label .. ' border')
        local box = tooltips[button].backgroundbox
        assert(box.bg == theme.tooltip_bg and box.fg == theme.tooltip_fg, label .. ' tooltip colors')
    end
end
check_selection('balanced')
awesome.emit_signal('module::power_profile', 'power-saver')
check_selection('power-saver')
for _, name in ipairs({ 'performance', 'power-saver', 'balanced' }) do
    buttons[name].click()
    assert(current == name, 'Click did not select ' .. name)
    check_selection(name)
    apply_palette('dark')
    check_selection(name)
    apply_palette('light')
    check_selection(name)
end
print('power profile selection, tooltips and live theme tests passed')

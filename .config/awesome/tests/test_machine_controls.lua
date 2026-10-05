-- Load real layouts with capability fixtures, never probing CI host hardware.
local home = assert(os.getenv('HOME'))
local root_dir = home .. '/.config/awesome/'
package.path = root_dir .. '?.lua;' .. root_dir .. '?/init.lua;' .. package.path
local config = { machine = 'laptop', keyboard = { file = '/fixture/keyboard-light' } }
local resources = true
package.loaded['configuration.config'] = config
package.loaded['gears.filesystem'] = {
    file_readable = function(path)
        assert(path == '/sys/class/power_supply/BAT0/type' or path == config.keyboard.file)
        return resources
    end,
    file_executable = function(path)
        assert(path == '/usr/bin/powerprofilesctl'); return resources
    end,
}
local constructions, loaded, capabilities = {}, {}, nil
local function widget(spec)
    local value = spec or {}
    constructions[#constructions + 1] = value
    function value:buttons() end

    function value:connect_signal() end

    function value:emit_signal() end

    function value:struts() end

    function value:setup(contents) self.contents = contents end

    function value:get_children_by_id() return { { visible = false } } end

    return value
end
package.loaded.wibox = setmetatable({
    widget = setmetatable({ separator = {}, systray = {} }, { __call = function(_, spec) return widget(spec) end }),
    layout = { align = {}, fixed = {}, flex = {}, stack = {} },
    container = { margin = {}, background = {} },
}, { __call = function(_, spec) return widget(spec) end })
package.loaded.gears = { shape = {}, timer = { start_new = function() end } }
package.loaded.beautiful = { xresources = { apply_dpi = function(n) return n end } }
package.loaded.awful = {
    popup = widget,
    placement = { top_right = function() end },
    button = function() end,
    util = { table = { join = function() end } }
}
package.loaded['layout.center-backdrop'] = { show = function() end }
package.loaded['layout.center-manager'] = { open = function() end, close = function() end }
package.loaded['layout.center-geometry'] = {
    width = function(s) return s.geometry.width / 6 end,
    bind = function() end,
}
package.loaded['layout.systray-cursor'] = { apply = function() return true end }
awesome = { emit_signal = function() end }
screen = { connect_signal = function() end, count = function() return 1 end }

for _, name in ipairs({
    'airplane-mode', 'bluetooth-toggle', 'blue-light', 'microphone-toggle', 'dont-disturb',
    'blur-toggle', 'presentation-mode', 'blur-slider', 'brightness-slider', 'volume-slider',
    'cpu-meter', 'ram-meter', 'temperature-meter', 'harddrive-meter', 'vseparator',
}) do package.preload['widget.' .. name] = function() return widget() end end
for _, name in ipairs({
    'user-profile', 'control-center-switch', 'end-session', 'task-list', 'clock', 'layoutbox',
    'tray-toggle', 'screen-recorder', 'playerctl-center-toggle', 'kbd-battery', 'vpn',
    'control-center-toggle', 'info-center-toggle',
}) do package.preload['widget.' .. name] = function() return function() return widget() end end end
package.preload['widget.tag-list'] = function() return { create = function() return widget() end } end
for _, name in ipairs({ 'battery', 'power-profile', 'kbd-brightness-slider' }) do
    package.preload['widget.' .. name] = function()
        local enabled = name == 'battery' and capabilities.battery or
            name == 'power-profile' and capabilities.power_profile or
            name == 'kbd-brightness-slider' and capabilities.keyboard_backlight
        assert(enabled, 'Unsupported widget was imported: ' .. name)
        loaded[name] = true
        return name == 'battery' and function() return widget { visible = true } end or widget()
    end
end

local function check(kind, present, expected)
    config.machine, resources = kind, present
    capabilities = dofile(root_dir .. 'library/machine.lua')
    assert(capabilities.battery == expected and capabilities.power_profile == expected and
        capabilities.keyboard_backlight == expected, 'Incorrect capability decisions')
    package.loaded['library.machine'] = capabilities
    for _, name in ipairs({ 'battery', 'power-profile', 'kbd-brightness-slider' }) do package.loaded['widget.' .. name] = nil end
    constructions, loaded = {}, {}
    local s = {
        valid = true,
        geometry = { x = 0, y = 0, width = 1200, height = 900 },
        top_panel = widget { visible = true, height = 46 },
        index = 1
    }
    screen.primary = s
    dofile(root_dir .. 'layout/control-center/init.lua')(s)
    dofile(root_dir .. 'layout/top-panel.lua')(s)
    local sliders
    for _, spec in ipairs(constructions) do if spec.id == 'control_sliders' then sliders = spec end end
    assert(sliders and #sliders == (expected and 5 or 3), 'Disabled controls left empty cards')
    assert((loaded.battery == true) == expected, 'Battery constructor selection failed')
    assert(s.battery.visible == expected, 'Hidden battery placeholder is incorrect')
end
check('laptop', true, true)
check('imac', true, false)
check('desktop', true, false)
check('laptop', false, false)
print('machine capability and optional-widget construction tests passed')

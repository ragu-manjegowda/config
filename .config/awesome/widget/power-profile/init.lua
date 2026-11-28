local bindings = require('theme.bindings')
local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')

local helper = gears.filesystem.get_configuration_dir() .. 'utilities/power/power-profile'
local profiles = {
    {
        key = 'performance',
        label = 'Performance',
        role = 'system_green_light',
        tooltip = '100% brightness · keep Bluetooth state · CPU performance · turbo on',
    },
    {
        key = 'balanced',
        label = 'Balanced',
        role = 'system_yellow_light',
        tooltip = '60% brightness · keep Bluetooth state · balanced CPU policy',
    },
    {
        key = 'power-saver',
        label = 'Power Saver',
        role = 'system_red_light',
        tooltip = '35% brightness · Bluetooth off · CPU power policy · turbo off',
    },
}
local buttons = {}

local action_name = wibox.widget {
    text = 'Power Profile',
    font = beautiful.font_bold(12),
    align = 'left',
    widget = wibox.widget.textbox,
}

local function update_widget(active_profile)
    for _, profile in ipairs(profiles) do
        local button = buttons[profile.key]
        if button then
            local selected = profile.key == active_profile
            button.shape_border_width = selected and dpi(2) or dpi(1)
            bindings.bind(button, {
                bg = selected and 'accent' or 'background',
                fg = selected and 'background' or profile.role,
                shape_border_color = selected and 'accent' or 'background_light',
            })
        end
    end
end

local function refresh_profile()
    awful.spawn.easy_async({ '/bin/bash', helper, 'get' }, function(stdout, _, _, exit_code)
        local profile = stdout:match('([%w%-]+)')
        update_widget(exit_code == 0 and profile or nil)
    end)
end

local function select_profile(profile)
    awful.spawn.easy_async({ '/bin/bash', helper, 'set', profile }, function(stdout, _, _, exit_code)
        local active_profile = stdout:match('([%w%-]+)')
        if exit_code == 0 and active_profile then
            update_widget(active_profile)
            awesome.emit_signal('module::power_profile', active_profile)
        else
            refresh_profile()
        end
    end)
end

local selector = wibox.widget {
    layout = wibox.layout.flex.horizontal,
    spacing = dpi(5),
}

for _, profile in ipairs(profiles) do
    local label = wibox.widget {
        text = profile.label,
        font = beautiful.font_bold(12),
        align = 'center',
        valign = 'center',
        forced_width = dpi(118),
        widget = wibox.widget.textbox,
    }
    local button = wibox.widget {
        {
            {
                label,
                margins = dpi(6),
                widget = wibox.container.margin,
            },
            forced_height = dpi(40),
            widget = clickable_container,
        },
        shape = gears.shape.rounded_rect,
        shape_border_width = dpi(1),
        shape_border_color = beautiful.transparent,
        forced_height = dpi(40),
        widget = bindings.widget(wibox.container.background, { bg = 'background', fg = profile.role }),
    }

    button:buttons(gears.table.join(
        awful.button({}, 1, nil, function() select_profile(profile.key) end)
    ))
    buttons[profile.key] = button
    awful.tooltip {
        objects = { button },
        text = profile.tooltip,
        mode = 'outside',
        align = 'bottom',
        margin_leftright = dpi(8),
        margin_topbottom = dpi(8),
    }
    selector:add(button)
end

awesome.connect_signal('control_center::visibility', function(visible)
    if visible then refresh_profile() end
end)

awesome.connect_signal('module::power_profile', update_widget)
refresh_profile()

return wibox.widget {
    layout = wibox.layout.fixed.vertical,
    forced_height = dpi(80),
    spacing = dpi(5),
    action_name,
    selector,
}

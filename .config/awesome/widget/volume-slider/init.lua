local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local spawn = awful.spawn
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')
local clickable_container = require('widget.clickable-container')

local action_name = wibox.widget {
    text = 'Volume',
    font = 'Hack Nerd Bold 12',
    align = 'left',
    widget = wibox.widget.textbox
}

local volume_icon = wibox.widget {
    image = icons.volume_muted,
    resize = true,
    widget = wibox.widget.imagebox
}

local icon = wibox.widget {
    layout = wibox.layout.align.vertical,
    expand = 'none',
    nil,
    volume_icon,
    nil
}

local action_level = wibox.widget {
    {
        {
            icon,
            margins = dpi(5),
            widget = wibox.container.margin
        },
        widget = clickable_container,
    },
    bg = beautiful.groups_bg,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
    end,
    widget = wibox.container.background
}

local slider = wibox.widget {
    nil,
    {
        id                  = 'volume_slider',
        bar_shape           = gears.shape.rounded_rect,
        bar_height          = dpi(24),
        bar_color           = beautiful.background,
        bar_active_color    = beautiful.accent,
        handle_color        = beautiful.accent,
        handle_shape        = gears.shape.circle,
        handle_width        = dpi(24),
        handle_border_color = beautiful.background,
        handle_border_width = dpi(1),
        maximum             = 100,
        widget              = wibox.widget.slider
    },
    nil,
    expand = 'none',
    forced_height = dpi(24),
    layout = wibox.layout.align.vertical
}

local volume_slider = slider.volume_slider

volume_slider:connect_signal(
    'property::value',
    function()
        local volume_level = volume_slider:get_value()

        spawn('wpctl set-volume @DEFAULT_AUDIO_SINK@ ' ..
            volume_level .. '%',
            false
        )

        -- Update volume osd
        awesome.emit_signal(
            'module::volume_osd',
            volume_level
        )
    end
)

local update_slider = function()
    local cmd = "wpctl get-volume @DEFAULT_AUDIO_SINK@"
    awful.spawn.easy_async_with_shell(
        cmd,
        function(stdout)
            local muted = string.match(stdout, 'MUTED')
            if muted ~= 'MUTED' then
                -- Volume: 0.95
                -- Extracting the decimal value using pattern matching
                local volume = string.match(stdout, "%d+%.%d+")

                -- Convert slider value from percentage to absolute value
                local slider_value = tonumber(volume * 100)

                volume_slider:set_value(slider_value)
                volume_icon:set_image(icons.volume)
            else
                volume_icon:set_image(icons.volume_muted)
            end

            awesome.emit_signal(
                'module::volume_osd:update_icon',
                muted == 'MUTED'
            )
        end
    )
end

-- Update on startup
update_slider()

local action_jump = function()
    local sli_value = volume_slider:get_value()
    local new_value = 0

    if sli_value >= 0 and sli_value < 50 then
        new_value = 50
        volume_icon:set_image(icons.volume)
    elseif sli_value >= 50 and sli_value < 100 then
        new_value = 100
    else
        new_value = 0
        volume_icon:set_image(icons.volume_muted)
    end
    volume_slider:set_value(new_value)
end

action_level:buttons(
    awful.util.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                action_jump()
            end
        )
    )
)

-- The emit will come from the global keybind
awesome.connect_signal(
    'widget::volume',
    function()
        update_slider()
    end
)

-- The emit will come from the OSD
awesome.connect_signal(
    'widget::volume:update',
    function(value)
        volume_slider:set_value(tonumber(value))
    end
)

local volume_setting = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    forced_height = dpi(48),
    spacing = dpi(5),
    action_name,
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(5),
        {
            layout = wibox.layout.align.vertical,
            expand = 'none',
            nil,
            {
                layout = wibox.layout.fixed.horizontal,
                forced_height = dpi(24),
                forced_width = dpi(24),
                action_level
            },
            nil
        },
        slider
    }
}

local myvolumemeter_t = awful.tooltip {}

myvolumemeter_t:add_to_object(volume_setting)

volume_setting:connect_signal('mouse::enter', function()
    myvolumemeter_t.text = 'Volume = ' .. tostring(volume_slider:get_value()) .. '%'
end)

return volume_setting

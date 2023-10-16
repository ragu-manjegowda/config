local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')
local clickable_container = require('widget.clickable-container')
local config = require('configuration.config')

local action_name = wibox.widget {
    text = 'KBD-Brightness',
    font = 'Hack Nerd Bold 12',
    align = 'left',
    widget = wibox.widget.textbox
}

local icon = wibox.widget {
    layout = wibox.layout.align.vertical,
    expand = 'none',
    nil,
    {
        image = icons.kbd_brightness,
        resize = true,
        widget = wibox.widget.imagebox
    },
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
        id                  = 'kbd_brightness_slider',
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

local kbd_brightness_slider = slider.kbd_brightness_slider

kbd_brightness_slider:connect_signal(
    'property::value',
    function()
        local kbd_brightness_path = config.keyboard.file
        local kbd_brightness_level = kbd_brightness_slider:get_value()

        local kbd_brightness_level_absolute = 0

        if string.find(kbd_brightness_path, "smc") then
            kbd_brightness_level_absolute = math.floor(kbd_brightness_level * (255 / 100))
        elseif string.find(kbd_brightness_path, "tpacpi") or
            string.find(kbd_brightness_path, "dell") then
            kbd_brightness_level_absolute = math.floor(kbd_brightness_level * (2 / 100))
        end

        local bkl_set_command =
            "echo " ..
            tostring(kbd_brightness_level_absolute) ..
            " > " .. kbd_brightness_path

        awful.spawn.with_shell(bkl_set_command)

        -- Update brightness osd
        awesome.emit_signal(
            'module::kbd_brightness_osd',
            kbd_brightness_level
        )
    end
)

local update_slider = function()
    local kbd_brightness_path = config.keyboard.file
    local bkl_get_command = "cat " .. kbd_brightness_path

    -- spawn.easy_async_with_shell or easy_async gives error in awmtt
    -- `attempt to call a boolean value`
    awful.spawn(
        bkl_get_command,
        function(stdout)
            local kbd_brightness = string.match(stdout, '(%d+)')

            if string.find(kbd_brightness_path, "smc") then
                kbd_brightness_slider:set_value((tonumber(kbd_brightness) / 255) * 100)
            elseif string.find(kbd_brightness_path, "tpacpi") or
                string.find(kbd_brightness_path, "dell") then
                kbd_brightness_slider:set_value((tonumber(kbd_brightness) / 2) * 100)
            end
        end
    )
end

-- Update on startup
update_slider()

local action_jump = function()
    local sli_value = kbd_brightness_slider:get_value()
    local new_value = 0

    if sli_value >= 0 and sli_value < 50 then
        new_value = 50
    elseif sli_value >= 50 and sli_value < 100 then
        new_value = 100
    else
        new_value = 0
    end
    kbd_brightness_slider:set_value(new_value)
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
    'widget::kbd_brightness',
    function()
        update_slider()
    end
)

-- The emit will come from the OSD
awesome.connect_signal(
    'widget::kbd_brightness:update',
    function(value)
        kbd_brightness_slider:set_value(tonumber(value))
    end
)

local kbd_brightness_setting = wibox.widget {
    layout = wibox.layout.fixed.vertical,
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

local mykbdbrightnessmeter_t = awful.tooltip {}

mykbdbrightnessmeter_t:add_to_object(kbd_brightness_setting)

kbd_brightness_setting:connect_signal('mouse::enter', function()
    mykbdbrightnessmeter_t.text = 'KBD-Brightness value = ' ..
        tostring(math.floor(kbd_brightness_slider:get_value())) .. '%'
end)

return kbd_brightness_setting

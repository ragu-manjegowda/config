local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local awful = require('awful')
local gfs = require('gears.filesystem')
local clickable_container = require('widget.clickable-container')

local config_dir = gfs.get_configuration_dir()
local icon_dir = config_dir .. 'widget/kbd-battery/icons/'

local return_button = function()
    local left_imagebox = wibox.widget {
        nil,
        {
            id = 'left_icon',
            image = icon_dir .. 'kinesis-left-cropped.svg',
            widget = wibox.widget.imagebox,
            resize = true
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    }

    local left_text = wibox.widget {
        id = 'left_text',
        text = '0%',
        font = beautiful.font_bold(12),
        align = 'center',
        valign = 'center',
        visible = true,
        widget = wibox.widget.textbox
    }

    local right_imagebox = wibox.widget {
        nil,
        {
            id = 'right_icon',
            image = icon_dir .. 'kinesis-right-cropped.svg',
            widget = wibox.widget.imagebox,
            resize = true
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    }

    local right_text = wibox.widget {
        id = 'right_text',
        text = '0%',
        font = beautiful.font_bold(12),
        align = 'center',
        valign = 'center',
        visible = true,
        widget = wibox.widget.textbox
    }

    local kbd_battery_widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(2),
        {
            left_imagebox,
            margins = dpi(3),
            widget = wibox.container.margin
        },
        left_text,
        {
            right_imagebox,
            margins = dpi(3),
            widget = wibox.container.margin
        },
        right_text
    }

    local kbd_battery_button = wibox.widget {
        {
            kbd_battery_widget,
            margins = dpi(7),
            widget = wibox.container.margin
        },
        widget = clickable_container
    }

    -- Tooltip showing more info
    local tooltip = awful.tooltip {
        objects = { kbd_battery_button },
        text = 'Kinesis Keyboard Battery\nLeft / Right',
        mode = 'outside',
        align = 'top'
    }

    -- Cache for battery levels
    local battery_cache = {
        left = 'N/A',
        right = 'N/A',
        connected = false
    }

    local update_display = function()
        if not battery_cache.connected then
            left_text:set_text('✗')
            right_text:set_text('✗')
        else
            if battery_cache.left == 'N/A' or battery_cache.right == 'N/A' then
                left_text:set_text('N/A')
                right_text:set_text('N/A')
            else
                left_text:set_text(battery_cache.left .. '%')
                right_text:set_text(battery_cache.right .. '%')
            end
        end
    end

    local read_battery_levels = function()
        -- Use DBus to automatically discover keyboards with battery service
        awful.spawn.easy_async_with_shell(
            'sh /home/ragu/.config/awesome/utilities/read-kbd-battery',
            function(stdout)
                if stdout == nil or stdout == '' then
                    battery_cache.connected = false
                    update_display()
                    return
                end

                stdout = stdout:gsub('%s+$', '') -- trim trailing whitespace

                if stdout == 'disconnected' then
                    battery_cache.connected = false
                    update_display()
                    return
                end

                local left, right = stdout:match('(%d+)%s+(%d+)')
                if left and right then
                    battery_cache.left = tonumber(left)
                    battery_cache.right = tonumber(right)
                    battery_cache.connected = true
                else
                    battery_cache.connected = false
                end

                update_display()
            end
        )
    end

    -- Poll battery every 5 hours (18000 seconds)
    local battery_timer = gears.timer {
        timeout = 18000,
        autostart = true,
        callback = function()
            read_battery_levels()
        end
    }

    -- Update on click (manual refresh)
    kbd_battery_button:connect_signal('button::press', function()
        read_battery_levels()
    end)

    -- Initial read
    read_battery_levels()

    return kbd_battery_button
end

return return_button

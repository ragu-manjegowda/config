local awful = require('awful')
local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')
local apps = require('configuration.apps')
local battery = require('library.battery')
local clickable_container = require('widget.clickable-container')
local dpi = require('beautiful').xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/battery/icons/'

local return_button = function()

    local battery_imagebox = wibox.widget {
        nil,
        {
            id = 'icon',
            image = widget_icon_dir .. 'battery' .. '.svg',
            widget = wibox.widget.imagebox,
            resize = true
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    }

    local battery_percentage_text = wibox.widget {
        id = 'percent_text',
        text = '100%',
        font = 'Hack Nerd Bold 14',
        align = 'center',
        valign = 'center',
        visible = false,
        widget = wibox.widget.textbox
    }


    local battery_widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(0),
        battery_imagebox,
        battery_percentage_text
    }


    local battery_button = wibox.widget {
        {
            battery_widget,
            margins = dpi(7),
            widget = wibox.container.margin
        },
        widget = clickable_container
    }

    battery_button:buttons(
        gears.table.join(
            awful.button(
                {},
                1,
                nil,
                function()
                    awful.spawn(apps.default.power_manager , false)
                end
            )
        )
    )

    local battery_tooltip =  awful.tooltip {
        objects = {battery_button},
        text = 'None',
        mode = 'outside',
        align = 'right',
        margin_leftright = dpi(8),
        margin_topbottom = dpi(8),
        preferred_positions = {'right', 'left', 'top', 'bottom'}
    }


    local get_battery_info = function()
        awful.spawn.easy_async_with_shell(
            'upower -i $(upower -e | grep BAT)',
            function(stdout)
                if stdout == nil or stdout == '' then
                    battery_tooltip:set_text('No battery detected!')
                    return
                end

                -- Remove new line from the last line
                battery_tooltip:set_text(stdout:sub(1, -2))
            end
        )
    end
    get_battery_info()

    battery_widget:connect_signal(
        'mouse::enter',
        function()
            get_battery_info()
        end
    )

    local last_battery_check = os.time()
    local notify_critcal_battery = true

    local show_battery_warning = function()
        naughty.notification ({
            icon = widget_icon_dir .. 'battery-alert.svg',
            app_name = 'System notification',
            title = 'Battery is dying!',
            message = 'Hey, I think we have a problem here. ' ..
                      'Save your work before reaching the oblivion.',
            urgency = 'critical'
        })
    end

    local update_battery = function(battery_percentage)
        awful.spawn.easy_async_with_shell(
            [[sh -c "
                upower -i $(upower -e | grep BAT) | grep state | \
                awk '{print \$2}' | tr -d '\n'
            "]],
            function(stdout)
                status = stdout:gsub('%\n', '')

                -- If no output or no battery detected
                if status == nil or status == '' then
                    battery_widget.spacing = dpi(0)
                    battery_percentage_text.visible = false
                    battery_tooltip:set_text('No battery detected!')
                    battery_imagebox.icon:set_image(
                        gears.surface.load_uncached(
                            widget_icon_dir .. 'battery-unknown' .. '.svg'))
                end

                battery_widget.spacing = dpi(5)
                battery_percentage_text.visible = true
                battery_percentage_text:set_text(battery_percentage .. '%')

                local icon_name = 'battery'

                -- Fully charged
                if (status == 'fully-charged' or status == 'charging') and
                    battery_percentage == 100 then
                    icon_name = icon_name .. '-' .. 'fully-charged'
                    battery_imagebox.icon:set_image(
                        gears.surface.load_uncached(
                            widget_icon_dir .. icon_name .. '.svg'))
                    return
                end

                -- Critical level warning message
                if (battery_percentage > 0 and battery_percentage < 20) and
                    status == 'discharging' then
                    icon_name = icon_name .. '-' .. 'alert-red'

                    if os.difftime(os.time(), last_battery_check) > 300 or
                       notify_critcal_battery then
                        last_battery_check = os.time()
                        notify_critcal_battery = false
                        show_battery_warning()
                    end
                    battery_imagebox.icon:set_image(
                        gears.surface.load_uncached(
                            widget_icon_dir .. icon_name .. '.svg'))
                    return
                end

                -- Discharging
                --if battery_percentage > 0 and battery_percentage < 20 then
                --  icon_name = icon_name .. '-' .. status .. '-' .. '10'

                --else
                if battery_percentage >= 20 and battery_percentage < 30 then
                    icon_name = icon_name .. '-' .. status .. '-' .. '20'

                elseif battery_percentage >= 30 and battery_percentage < 50 then
                    icon_name = icon_name .. '-' .. status .. '-' .. '30'

                elseif battery_percentage >= 50 and battery_percentage < 60 then
                    icon_name = icon_name .. '-' .. status .. '-' .. '50'

                elseif battery_percentage >= 60 and battery_percentage < 80 then
                    icon_name = icon_name .. '-' .. status .. '-' .. '60'

                elseif battery_percentage >= 80 and battery_percentage < 90 then
                    icon_name = icon_name .. '-' .. status .. '-' .. '80'

                elseif battery_percentage >= 90 and battery_percentage < 100 then
                    icon_name = icon_name .. '-' .. status .. '-' .. '90'
                end

                battery_imagebox.icon:set_image(
                    gears.surface.load_uncached(
                        widget_icon_dir .. icon_name .. '.svg'))
            end
        )
    end

    -- Create the battery widget:
    local my_battery_widget = battery {
        screen = screen,
        device_path = '/org/freedesktop/UPower/devices/battery_BAT0',
        instant_update = true,
        widget_template = wibox.widget.textbox
    }

    -- When UPower updates the battery status, the widget is notified
    -- and calls a signal you need to connect to:
    my_battery_widget:connect_signal('upower::update',
        function (widget, device)
            update_battery(tonumber(string.format('%3d', device.percentage)))
    end)

    return battery_button
end

return return_button

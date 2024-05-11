local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')
local watch = awful.widget.watch
local clickable_container = require('widget.clickable-container')
local dpi = require('beautiful').xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/vpn/icons/'

local return_button = function()
    local vpn_imagebox = wibox.widget {
        nil,
        {
            id = 'icon',
            image = widget_icon_dir .. 'vpn' .. '.png',
            widget = wibox.widget.imagebox,
            resize = true,
            visible = false
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    }

    local vpn_percentage_text = wibox.widget {
        id = 'percent_text',
        text = 'vpn',
        font = 'Hack Nerd Bold 14',
        align = 'center',
        valign = 'center',
        visible = false,
        widget = wibox.widget.textbox
    }


    local vpn_widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(0),
        vpn_imagebox,
        vpn_percentage_text
    }


    local vpn_button = wibox.widget {
        {
            vpn_widget,
            margins = dpi(7),
            widget = wibox.container.margin
        },
        widget = clickable_container
    }

    vpn_button:buttons(
        gears.table.join(
            awful.button(
                {},
                1,
                nil,
                function()
                end
            )
        )
    )

    vpn_widget:connect_signal(
        'mouse::enter',
        function()
        end
    )

    local last_status = "Disconnected"

    local show_vpn_warning = function(vpn_percentage)
        if last_status == tostring(vpn_percentage) then
            return
        end

        last_status = tostring(vpn_percentage)

        naughty.notification({
            icon = widget_icon_dir .. 'vpn.png',
            app_name = 'System notification',
            title = 'VPN ' .. tostring(vpn_percentage),
            urgency = 'normal'
        })
    end

    local update_vpn = function()
        awful.spawn.easy_async_with_shell(
            [[
            /opt/cisco/anyconnect/bin/vpn state | grep "state:" | awk 'NR==1{print $4}'
        	]],
            function(stdout)
                local vpn_percentage = stdout
                --naughty.notify({text = tostring(stdout)})
                show_vpn_warning(vpn_percentage)

                vpn_imagebox.icon.visible = true
                vpn_widget.spacing = dpi(5)
                vpn_percentage_text.visible = true
                vpn_percentage_text:set_text(vpn_percentage)
            end
        )
    end

    -- Watch status if connected, disconnected
    watch(
        [[
            /opt/cisco/anyconnect/bin/vpn state
        ]],
        5,
        function(_, _)
            update_vpn()
        end
    )

    return vpn_button
end

return return_button

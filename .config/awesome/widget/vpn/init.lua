local awful = require('awful')
local gears = require('gears')
local wibox = require('wibox')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local status_command = config_dir .. 'utilities/prisma-vpn-status'
local icon = config_dir .. 'widget/vpn/icons/prisma-access.svg'
local current_status = 'disconnected'

-- Keep one watcher for all screens. The returned objects must remain referenced.
local status_widget, status_timer = awful.widget.watch(
    status_command,
    5,
    function(_, stdout)
        local status = stdout:match('^%s*(%a+)') or 'unavailable'
        if status ~= 'connected' and status ~= 'connecting' and
            status ~= 'disconnected' and status ~= 'unavailable' then
            status = 'unavailable'
        end

        if status ~= current_status then
            current_status = status
            awesome.emit_signal('module::vpn_status', status)
        end
    end
)

local return_button = function()
    -- Keep the singleton timer reachable and running across panel recreation.
    status_timer:again()

    local vpn_imagebox = wibox.widget {
        image = icon,
        resize = true,
        forced_width = dpi(24),
        forced_height = dpi(24),
        widget = wibox.widget.imagebox
    }

    local vpn_widget = wibox.widget {
        vpn_imagebox,
        top = dpi(7),
        bottom = dpi(7),
        left = dpi(4),
        right = 0,
        visible = false,
        widget = wibox.container.margin
    }

    local tooltip = awful.tooltip {
        objects = { vpn_widget },
        text = 'VPN disconnected',
        mode = 'outside',
        align = 'right'
    }

    local has_connected = false
    local hide_timer = gears.timer {
        timeout = 120,
        single_shot = true,
        callback = function()
            vpn_widget.visible = false
        end
    }

    local update_vpn = function(status)
        tooltip:set_text('VPN ' .. status)

        if status == 'connected' then
            has_connected = true
            hide_timer:stop()
            vpn_widget.visible = true
        elseif status == 'connecting' then
            hide_timer:stop()
            vpn_widget.visible = true
        elseif has_connected or vpn_widget.visible then
            has_connected = false
            vpn_widget.visible = true
            hide_timer:again()
        else
            vpn_widget.visible = false
        end
    end

    awesome.connect_signal('module::vpn_status', update_vpn)
    update_vpn(current_status)

    return vpn_widget
end

return return_button

local awful = require('awful')
local gears = require('gears')
local wibox = require('wibox')
local beautiful = require('beautiful')
local naughty = require('naughty')
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local status_command = config_dir .. 'utilities/prisma-vpn-status'
local health_command = config_dir .. 'utilities/prisma-vpn-health'
local diagnostics_command = config_dir .. 'utilities/prisma-vpn-diagnostics'
local icon = config_dir .. 'widget/vpn/icons/prisma-access.svg'
local unhealthy_icon = config_dir .. 'widget/vpn/icons/prisma-access-unhealthy.svg'
local current_status = 'disconnected'
local current_health = 'unknown'
local health_failures = 0
local health_check_running = false
local health_reported = false
local health_generation = 0
local last_health_check = 0
local health_interval_seconds = 60
local health_failure_threshold = 3
local mail_restart_timer = gears.timer {
    timeout = 2,
    single_shot = true,
    callback = function()
        awful.spawn({
            'systemctl', '--user', 'try-restart', 'goimapnotify.service'
        }, false)
    end
}

local function set_health(health)
    if health ~= current_health then
        current_health = health
        awesome.emit_signal('module::vpn_health', health)
    end
end

local function capture_health_failure(generation)
    awful.spawn.easy_async({ diagnostics_command }, function(stdout)
        if generation ~= health_generation or current_status ~= 'connected' then return end
        local diagnostic_path = stdout:match('([^%s]+%.log)') or 'the Prisma state directory'
        naughty.notification({
            title = 'VPN connectivity lost',
            message = 'Prisma reports connected, but Outlook is unreachable over IPv4. ' ..
                'Diagnostics: ' .. diagnostic_path,
            urgency = 'critical',
            timeout = 0
        })
    end)
end

local function check_health()
    if health_check_running or os.time() - last_health_check < health_interval_seconds then
        return
    end

    last_health_check = os.time()
    health_check_running = true
    local generation = health_generation
    awful.spawn.easy_async({ health_command }, function(_, _, _, exit_code)
        if generation ~= health_generation or current_status ~= 'connected' then return end
        health_check_running = false
        if exit_code == 0 then
            health_failures = 0
            health_reported = false
            set_health('healthy')
            return
        end

        health_failures = health_failures + 1
        if health_failures >= health_failure_threshold then
            set_health('unhealthy')
            if not health_reported then
                health_reported = true
                capture_health_failure(generation)
            end
        else
            set_health('degraded')
        end
    end)
end

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
            -- Old probes/diagnostics must not update a new VPN connection.
            health_generation = health_generation + 1
            health_check_running = false
            last_health_check = 0
            awesome.emit_signal('module::vpn_status', status)
            if status == 'connected' or status == 'disconnected' then
                mail_restart_timer:again()
            end
        end

        if status == 'connected' then
            check_health()
        else
            health_failures = 0
            health_reported = false
            last_health_check = 0
            set_health('unknown')
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
        local health_text = current_health == 'unknown' and '' or ' (' .. current_health .. ')'
        tooltip:set_text('VPN ' .. status .. health_text)
        vpn_imagebox.image = current_health == 'unhealthy' and unhealthy_icon or icon

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
    awesome.connect_signal('module::vpn_health', function()
        update_vpn(current_status)
    end)
    update_vpn(current_status)

    return vpn_widget
end

return return_button

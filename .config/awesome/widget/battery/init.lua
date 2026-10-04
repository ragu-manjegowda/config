local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local naughty = require('naughty')
local check_battery_alert = require('library.battery-alert').new()
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/battery/icons/'

-- Try to load battery library, return dummy widget if it fails (CI environment)
local battery_lib, battery = pcall(require, 'library.battery')
if not battery_lib then
    return function()
        return wibox.widget {
            {
                text = 'N/A',
                font = beautiful.font_bold(12),
                align = 'center',
                valign = 'center',
                widget = wibox.widget.textbox
            },
            visible = false,
            widget = wibox.container.background
        }
    end
end
local upower = require('lgi').UPowerGlib

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
        font = beautiful.font_bold(12),
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
        widget = wibox.container.background
    }

    local battery_tooltip = awful.tooltip {
        objects = { battery_button },
        text = 'None',
        mode = 'outside',
        align = 'right',
        margin_leftright = dpi(8),
        margin_topbottom = dpi(8),
        preferred_positions = { 'right', 'left', 'top', 'bottom' }
    }
    local consumers_command = config_dir .. 'utilities/power/battery-power-consumers'
    local battery_summary = 'Battery status unavailable'
    local consumer_summary = ''

    local update_tooltip = function()
        local summary = string.rep(' ', #('CPU activity:') - #('Battery:')) ..
            'Battery: ' .. battery_summary .. consumer_summary
        battery_tooltip:set_markup(
            '<span font_family="Hack Nerd Font Mono">' .. gears.string.xml_escape(summary) .. '</span>'
        )
    end

    local get_battery_info = function()
        awful.spawn.easy_async_with_shell(
            'upower -i $(upower -e | grep BAT)',
            function(stdout)
                if stdout == nil or stdout == '' then
                    battery_summary = 'No battery detected!'
                    consumer_summary = ''
                    update_tooltip()
                    return
                end

                local function field(name)
                    return stdout:match('\n%s*' .. name .. ':%s*([^\n]+)')
                end

                local state = field('state') or 'unknown'
                local percentage = field('percentage') or 'Unknown'
                local label = ({
                    charging = 'Charging',
                    discharging = 'Discharging',
                    ['fully-charged'] = 'Fully charged',
                    ['pending-charge'] = 'Waiting to charge',
                    ['not charging'] = 'Not charging',
                })[state] or 'Battery status unavailable'
                local remaining

                if state == 'charging' then
                    remaining = field('time to full')
                elseif state == 'discharging' then
                    remaining = field('time to empty')
                    if not remaining then
                        local energy = tonumber((field('energy') or ''):match('[%d.]+'))
                        local rate = tonumber((field('energy-rate') or ''):match('[%d.]+'))
                        if energy and rate and rate > 0 then
                            local minutes = math.floor((energy / rate) * 60 + 0.5)
                            local hours = math.floor(minutes / 60)
                            remaining = hours > 0 and string.format('%dh %02dm', hours, minutes % 60) or
                                string.format('%dm', minutes)
                        end
                    end
                end

                local time_suffix = state == 'charging' and ' until full' or ' remaining'
                local summary = percentage .. ' · ' .. label
                if remaining then
                    summary = summary .. ' · ' .. remaining .. time_suffix
                end
                battery_summary = summary
                update_tooltip()
            end
        )
    end

    local get_power_consumers = function()
        awful.spawn.easy_async(
            { '/bin/bash', consumers_command },
            function(stdout, _, _, exit_code)
                consumer_summary = exit_code == 0 and '\n' .. stdout:gsub('%s+$', '') or ''
                update_tooltip()
            end
        )
    end

    get_battery_info()

    battery_widget:connect_signal(
        'mouse::enter',
        function()
            get_battery_info()
            get_power_consumers()
        end
    )

    local show_battery_warning = function(critical)
        naughty.notification({
            icon = widget_icon_dir .. 'battery-alert.svg',
            app_name = 'System notification',
            title = critical and 'Battery critically low!' or 'Battery is dying!',
            message = critical and 'Save your work; suspending now.' or
                'Save your work and connect power before the battery runs out.',
            urgency = 'critical'
        })
    end

    local suspend_on_critical_battery = function()
        awesome.emit_signal('module::suspend')
    end

    local update_battery = function(battery_percentage, device)
        local states = upower.DeviceState
        local status = 'unknown'
        if device.state == states.CHARGING then
            status = 'charging'
        elseif device.state == states.DISCHARGING or device.state == states.EMPTY then
            status = 'discharging'
        elseif device.state == states.FULLY_CHARGED then
            status = 'fully-charged'
        elseif device.state == states.PENDING_CHARGE then
            status = 'pending-charge'
        elseif device.state == states.PENDING_DISCHARGE then
            status = 'not charging'
        end
        if status == 'unknown' then
            battery_widget.spacing = dpi(0)
            battery_percentage_text.visible = false
            battery_tooltip:set_text('Battery status unavailable!')
            battery_imagebox.icon:set_image(
                gears.surface.load_uncached(
                ---@diagnostic disable-next-line: param-type-mismatch
                    widget_icon_dir .. 'battery-unknown.svg'))
            return
        end

        battery_widget.spacing = dpi(5)
        battery_percentage_text.visible = true
        battery_percentage_text:set_text(battery_percentage .. '%')

        local icon_name = 'battery'
        local alert = check_battery_alert(battery_percentage, status, device.update_time)
        if alert == 'critical' then
            show_battery_warning(true)
            suspend_on_critical_battery()
            return
        elseif alert == 'low' then
            show_battery_warning(false)
        end

        if (status == 'fully-charged' or status == 'charging') and
            battery_percentage == 100 then
            icon_name = icon_name .. '-fully-charged'
            battery_imagebox.icon:set_image(
                gears.surface.load_uncached(
                ---@diagnostic disable-next-line: param-type-mismatch
                    widget_icon_dir .. icon_name .. '.svg'))
            return
        end

        -- Only charging and discharging icon variants exist.
        local icon_status = status
        if status == 'fully-charged' or status == 'pending-charge' or
            status == 'not charging' then
            icon_status = 'charging'
        end

        if battery_percentage > 0 and battery_percentage < 20 then
            if status == 'discharging' then
                icon_name = icon_name .. '-alert-red'
                battery_imagebox.icon:set_image(
                    gears.surface.load_uncached(
                    ---@diagnostic disable-next-line: param-type-mismatch
                        widget_icon_dir .. icon_name .. '.svg'))
                return
            else
                icon_name = icon_name .. '-' .. icon_status .. '-10'
            end
        end

        if battery_percentage >= 20 and battery_percentage < 30 then
            icon_name = icon_name .. '-' .. icon_status .. '-20'
        elseif battery_percentage >= 30 and battery_percentage < 50 then
            icon_name = icon_name .. '-' .. icon_status .. '-30'
        elseif battery_percentage >= 50 and battery_percentage < 60 then
            icon_name = icon_name .. '-' .. icon_status .. '-50'
        elseif battery_percentage >= 60 and battery_percentage < 80 then
            icon_name = icon_name .. '-' .. icon_status .. '-60'
        elseif battery_percentage >= 80 and battery_percentage < 90 then
            icon_name = icon_name .. '-' .. icon_status .. '-80'
        elseif battery_percentage >= 90 and battery_percentage < 100 then
            icon_name = icon_name .. '-' .. icon_status .. '-90'
        elseif battery_percentage == 100 then
            icon_name = icon_name .. '-' .. icon_status .. '-100'
        end

        battery_imagebox.icon:set_image(
            gears.surface.load_uncached(
            ---@diagnostic disable-next-line: param-type-mismatch
                widget_icon_dir .. icon_name .. '.svg'))
    end

    -- Create the battery widget (wrapped in pcall for CI environment):
    local battery_ok, my_battery_widget = pcall(function()
        return battery {
            screen = screen,
            device_path = '/org/freedesktop/UPower/devices/battery_BAT0',
            instant_update = true,
            widget_template = wibox.widget.textbox
        }
    end)

    -- Handle battery library failure (CI environment without UPower)
    if not battery_ok or not my_battery_widget then
        return wibox.widget {
            {
                text = 'N/A',
                font = beautiful.font_bold(12),
                align = 'center',
                valign = 'center',
                widget = wibox.widget.textbox
            },
            visible = false,
            widget = wibox.container.background
        }
    end

    -- UPower notifies separately for changed properties in one sample. Let
    -- those changes settle before checking the sample's update timestamp.
    local pending_device
    local update_timer = gears.timer {
        timeout = 0.1,
        single_shot = true,
        callback = function()
            local device = pending_device
            pending_device = nil
            if device then
                update_battery(tonumber(string.format('%3d', device.percentage)), device)
            end
        end
    }
    my_battery_widget:connect_signal('upower::update',
        function(_, device)
            pending_device = device
            update_timer:again()
        end)

    return battery_button
end

return return_button

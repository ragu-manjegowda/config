local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local Gio = require('lgi').Gio
local wibox = require('wibox')
local clickable_container = require('widget.clickable-container')
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local icon_dir = config_dir .. 'widget/kbd-battery/icons/'
local battery_command = config_dir .. 'utilities/read-kbd-battery'

local current = {
    connected = false,
    left = 'N/A',
    right = 'N/A'
}
local refresh_in_progress = false
local refresh_pending = false
local battery_timer
local refresh_timer

local function publish(connected, left, right)
    local changed = current.connected ~= connected or
        current.left ~= left or current.right ~= right

    current.connected = connected
    current.left = left
    current.right = right

    if connected then
        battery_timer:again()
    else
        battery_timer:stop()
    end

    if changed then
        awesome.emit_signal('module::kbd_battery_status', connected, left, right)
    end
end

local function read_battery_levels()
    if refresh_in_progress then
        refresh_pending = true
        return
    end

    refresh_in_progress = true
    awful.spawn.easy_async({ '/usr/bin/timeout', '10', battery_command }, function(stdout)
        refresh_in_progress = false
        stdout = (stdout or ''):gsub('%s+$', '')

        local left, right = stdout:match('^(%d+)%s+(%d+)$')
        if left and right then
            publish(true, tonumber(left), tonumber(right))
        else
            publish(false, 'N/A', 'N/A')
        end

        if refresh_pending then
            refresh_pending = false
            refresh_timer:again()
        end
    end)
end

battery_timer = gears.timer {
    timeout = 18000,
    single_shot = true,
    callback = read_battery_levels
}

refresh_timer = gears.timer {
    timeout = 1,
    single_shot = true,
    callback = read_battery_levels
}

local bus_ok, system_bus = pcall(Gio.bus_get_sync, Gio.BusType.SYSTEM)
local subscriptions = {}
local function schedule_refresh()
    refresh_timer:again()
end

if bus_ok and system_bus then
    subscriptions[#subscriptions + 1] = system_bus:signal_subscribe(
        'org.bluez',
        'org.freedesktop.DBus.Properties',
        'PropertiesChanged',
        nil,
        nil,
        Gio.DBusSignalFlags.NONE,
        schedule_refresh
    )
    subscriptions[#subscriptions + 1] = system_bus:signal_subscribe(
        'org.bluez',
        'org.freedesktop.DBus.ObjectManager',
        'InterfacesAdded',
        '/',
        nil,
        Gio.DBusSignalFlags.NONE,
        schedule_refresh
    )
    subscriptions[#subscriptions + 1] = system_bus:signal_subscribe(
        'org.bluez',
        'org.freedesktop.DBus.ObjectManager',
        'InterfacesRemoved',
        '/',
        nil,
        Gio.DBusSignalFlags.NONE,
        schedule_refresh
    )
end

local return_button = function()
    -- Keep singleton timers and D-Bus subscriptions reachable across panels.
    refresh_timer:again()
    local subscription_count = #subscriptions

    local left_imagebox = wibox.widget {
        nil,
        {
            image = icon_dir .. 'kinesis-left-cropped.svg',
            widget = wibox.widget.imagebox,
            resize = true
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    }

    local left_text = wibox.widget {
        text = 'N/A',
        font = beautiful.font_bold(12),
        align = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    }

    local right_imagebox = wibox.widget {
        nil,
        {
            image = icon_dir .. 'kinesis-right-cropped.svg',
            widget = wibox.widget.imagebox,
            resize = true
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    }

    local right_text = wibox.widget {
        text = 'N/A',
        font = beautiful.font_bold(12),
        align = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    }

    local battery_content = wibox.widget {
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

    local battery_button = wibox.widget {
        {
            battery_content,
            margins = dpi(7),
            widget = wibox.container.margin
        },
        visible = false,
        widget = clickable_container
    }

    local tooltip = awful.tooltip {
        objects = { battery_button },
        text = 'Kinesis Keyboard Battery\nDisconnected',
        mode = 'outside',
        align = 'top'
    }

    local has_connected = false
    local hide_timer = gears.timer {
        timeout = 120,
        single_shot = true,
        callback = function()
            battery_button.visible = false
        end
    }

    local function update_display(connected, left, right)
        if connected then
            has_connected = true
            hide_timer:stop()
            left_text:set_text(left .. '%')
            right_text:set_text(right .. '%')
            tooltip:set_text(string.format(
                'Kinesis Keyboard Battery\nLeft: %s%%  Right: %s%%',
                left,
                right
            ))
            battery_button.visible = true
        elseif has_connected or battery_button.visible then
            has_connected = false
            left_text:set_text('✗')
            right_text:set_text('✗')
            tooltip:set_text('Kinesis Keyboard Battery\nDisconnected')
            battery_button.visible = true
            hide_timer:again()
        else
            battery_button.visible = false
        end
    end

    battery_button:connect_signal('button::press', schedule_refresh)
    awesome.connect_signal('module::kbd_battery_status', update_display)
    update_display(current.connected, current.left, current.right)

    return battery_button
end

return return_button

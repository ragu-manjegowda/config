local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local icons = require('theme.icons')

local mic_muted = false

local action_name = wibox.widget {
    text = 'Microphone',
    font = beautiful.font_bold(11),
    align = 'left',
    widget = wibox.widget.textbox
}

local action_status = wibox.widget {
    text = 'On',
    font = beautiful.font_regular(10),
    align = 'left',
    widget = wibox.widget.textbox
}

local action_info = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    action_name,
    action_status
}

local button_widget = wibox.widget {
    {
        id = 'icon',
        image = icons.microphone_high,
        widget = wibox.widget.imagebox,
        resize = true
    },
    layout = wibox.layout.align.horizontal
}

local widget_button = wibox.widget {
    {
        {
            button_widget,
            margins = dpi(15),
            forced_height = dpi(48),
            forced_width = dpi(48),
            widget = wibox.container.margin
        },
        widget = clickable_container
    },
    bg = beautiful.groups_bg,
    shape = gears.shape.circle,
    widget = wibox.container.background
}

local update_widget = function()
    if mic_muted then
        action_status:set_text('Muted')
        widget_button.bg = beautiful.groups_bg
        button_widget.icon:set_image(icons.microphone_muted)
    else
        action_status:set_text('On')
        widget_button.bg = beautiful.accent
        button_widget.icon:set_image(icons.microphone_high)
    end
end

local check_mic_status = function()
    awful.spawn.easy_async_with_shell(
        'wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -o MUTED',
        function(stdout)
            if stdout:match('MUTED') then
                mic_muted = true
            else
                mic_muted = false
            end
            update_widget()
        end
    )
end

check_mic_status()

local toggle_mic = function()
    awful.spawn('wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle', false)
    awful.spawn.easy_async_with_shell(
        'wpctl get-volume @DEFAULT_AUDIO_SOURCE@',
        function(stdout)
            mic_muted = stdout:match('%[MUTED%]') ~= nil
            update_widget()
            -- Emit signal to update OSD
            awesome.emit_signal('module::mic_osd:update', mic_muted)
            awesome.emit_signal('module::mic_osd:show', true)
        end
    )
end

widget_button:buttons(
    gears.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                toggle_mic()
            end
        )
    )
)

action_info:buttons(
    gears.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                toggle_mic()
            end
        )
    )
)

local action_widget = wibox.widget {
    layout = wibox.layout.fixed.horizontal,
    spacing = dpi(10),
    widget_button,
    {
        layout = wibox.layout.align.vertical,
        expand = 'none',
        nil,
        action_info,
        nil
    }
}

-- Monitor microphone state changes via pactl subscribe (cleaner than pw-mon)
local dbus_monitor = function()
    awful.spawn.with_line_callback(
        'pactl subscribe 2>/dev/null',
        {
            stdout = function(line)
                -- Only react to source (microphone) changes
                if line:match("Event 'change' on source") then
                    check_mic_status()
                end
            end
        }
    )
end

-- Start D-Bus monitoring in background (delayed to ensure D-Bus is ready)
gears.timer {
    timeout = 2,
    autostart = true,
    single_shot = true,
    callback = function()
        dbus_monitor()
    end
}

-- Subscribe to global mic OSD updates
awesome.connect_signal(
    'widget::microphone:update',
    function()
        check_mic_status()
    end
)

return action_widget

local awful = require('awful')
local gears = require('gears')
local wibox = require('wibox')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')

local mic_icon = wibox.widget {
    image = icons.microphone_high,
    resize = true,
    forced_height = dpi(240),
    forced_width = dpi(240),
    widget = wibox.widget.imagebox
}

local icon = wibox.widget {
    mic_icon,
    forced_height = dpi(240),
    top = dpi(12),
    bottom = dpi(12),
    widget = wibox.container.margin
}

local osd_margin = dpi(10)

screen.connect_signal(
    'request::desktop_decoration',
    function(s)
        s = s or {}

        s.mic_osd_overlay = awful.popup {
            widget = {
                -- Removing this block will cause an error...
            },
            ontop = true,
            visible = false,
            type = 'notification',
            screen = s,
            height = s.geometry.height / 4,
            width = s.geometry.width / 6,
            maximum_height = s.geometry.height / 4,
            maximum_width = s.geometry.width / 6,
            offset = dpi(5),
            shape = gears.shape.rectangle,
            bg = beautiful.transparent,
            preferred_anchors = 'middle',
            preferred_positions = { 'left', 'right', 'top', 'bottom' }
        }

        s.mic_osd_overlay:setup {
            {
                {
                    layout = wibox.layout.fixed.vertical,
                    {
                        layout = wibox.layout.align.horizontal,
                        expand = 'none',
                        nil,
                        icon,
                        nil
                    }
                },
                left = dpi(24),
                right = dpi(24),
                top = dpi(12),
                bottom = dpi(12),
                widget = wibox.container.margin
            },
            bg = beautiful.groups_bg .. "44",
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background()
        }

        -- Remove overlay when mouse right clicked
        s.mic_osd_overlay:connect_signal(
            'button::press',
            function(_, _, _, button)
                if button == 3 then
                    s.mic_osd_overlay.visible = false
                end
            end
        )
    end
)

local hide_osd = gears.timer {
    timeout   = 2,
    autostart = true,
    callback  = function()
        local focused = awful.screen.focused()
        focused.mic_osd_overlay.visible = false
    end
}

awesome.connect_signal(
    'module::mic_osd:rerun',
    function()
        if hide_osd.started then
            hide_osd:again()
        else
            hide_osd:start()
        end
    end
)

local placement_placer = function()
    local focused = awful.screen.focused()
    local mic_osd = focused.mic_osd_overlay
    awful.placement.bottom(
        mic_osd,
        {
            margins = {
                left = 0,
                right = 0,
                top = 0,
                bottom = osd_margin
            }
        }
    )
end

awesome.connect_signal(
    'module::mic_osd:update',
    function(muted)
        if muted then
            mic_icon:set_image(icons.microphone_muted)
            awful.screen.focused().mic_osd_overlay.fg = beautiful.background_light
        else
            mic_icon:set_image(icons.microphone_high)
            awful.screen.focused().mic_osd_overlay.fg = beautiful.fg_focus
        end
    end
)

awesome.connect_signal(
    'module::mic_osd:show',
    function(bool)
        placement_placer()
        awful.screen.focused().mic_osd_overlay.visible = bool
        if bool then
            awesome.emit_signal('module::mic_osd:rerun')
            awesome.emit_signal('module::volume_osd:show', false)
            awesome.emit_signal('module::brightness_osd:show', false)
            awesome.emit_signal('module::kbd_brightness_osd:show', false)
        else
            if hide_osd.started then
                hide_osd:stop()
            end
        end
    end
)

-- Handle microphone status update signal (check status before showing OSD)
awesome.connect_signal(
    'widget::microphone:update',
    function()
        awful.spawn.easy_async_with_shell(
            'wpctl get-volume @DEFAULT_AUDIO_SOURCE@',
            function(stdout)
                local muted = stdout:match('%[MUTED%]') ~= nil
                awesome.emit_signal('module::mic_osd:update', muted)
            end
        )
    end
)

-- Monitor microphone state changes via pactl subscribe (cleaner than pw-mon)
local dbus_monitor = function()
    awful.spawn.with_line_callback(
        'pactl subscribe 2>/dev/null',
        {
            stdout = function(line)
                -- Only react to source (microphone) changes
                if line:match("Event 'change' on source") then
                    -- Check current mic status and update widget + OSD
                    awful.spawn.easy_async_with_shell(
                        'wpctl get-volume @DEFAULT_AUDIO_SOURCE@',
                        function(stdout)
                            local muted = stdout:match('%[MUTED%]') ~= nil
                            awesome.emit_signal('module::mic_osd:update', muted)
                            awesome.emit_signal('widget::microphone:update')
                            awesome.emit_signal('module::mic_osd:show', true)
                        end
                    )
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

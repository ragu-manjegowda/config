local awful = require('awful')
local gears = require('gears')
local wibox = require('wibox')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')

local osd_header = wibox.widget {
    text = 'Microphone',
    font = beautiful.font_bold(14),
    align = 'left',
    valign = 'center',
    widget = wibox.widget.textbox
}

local osd_value = wibox.widget {
    text = 'Active',
    font = beautiful.font_bold(14),
    align = 'center',
    valign = 'center',
    widget = wibox.widget.textbox
}

local slider_osd = wibox.widget {
    nil,
    {
        bar_shape    = gears.shape.rounded_rect,
        bar_height   = dpi(24),
        bar_color    = beautiful.groups_bg,
        handle_color = beautiful.fg_focus,
        handle_shape = gears.shape.circle,
        handle_width = dpi(0),
        widget       = wibox.widget.slider
    },
    nil,
    expand = 'none',
    layout = wibox.layout.align.vertical
}

local icon = wibox.widget {
    {
        image = icons.microphone_high,
        resize = true,
        widget = wibox.widget.imagebox
    },
    forced_height = dpi(150),
    top = dpi(12),
    bottom = dpi(12),
    widget = wibox.container.margin
}

local osd_margin = dpi(10)

screen.connect_signal(
    'request::desktop_decoration',
    function(screen)
        local s = screen or {}

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
                        {
                            layout = wibox.layout.align.horizontal,
                            expand = 'none',
                            nil,
                            icon,
                            nil
                        },
                        {
                            layout = wibox.layout.fixed.vertical,
                            spacing = dpi(5),
                            {
                                layout = wibox.layout.align.horizontal,
                                expand = 'none',
                                osd_header,
                                nil,
                                osd_value
                            },
                            slider_osd
                        },
                        spacing = dpi(10),
                        layout = wibox.layout.fixed.vertical
                    },
                },
                left = dpi(24),
                right = dpi(24),
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
            icon.children[1]:set_image(icons.microphone_muted)
            osd_value.text = 'Muted'
        else
            icon.children[1]:set_image(icons.microphone_high)
            osd_value.text = 'Active'
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
            awesome.emit_signal(
                'module::kbd_brightness_osd:show',
                false
            )
            awesome.emit_signal(
                'module::volume_osd:show',
                false
            )
            awesome.emit_signal(
                'module::brightness_osd:show',
                false
            )
        else
            if hide_osd.started then
                hide_osd:stop()
            end
        end
    end
)

-- Handle microphone status update signal
awesome.connect_signal(
    'widget::microphone',
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

-- Monitor microphone state changes via pactl subscribe
local dbus_monitor = function()
    awful.spawn.with_line_callback(
        'pactl subscribe 2>/dev/null',
        {
            stdout = function(line)
                -- Only react to source (microphone) changes
                if line:match("Event 'change' on source") then
                    awful.spawn.easy_async_with_shell(
                        'wpctl get-volume @DEFAULT_AUDIO_SOURCE@',
                        function(stdout)
                            local muted = stdout:match('%[MUTED%]') ~= nil
                            -- Update OSD icon state
                            awesome.emit_signal('module::mic_osd:update', muted)
                            -- Update microphone widget state
                            awesome.emit_signal('widget::microphone')
                            -- Do NOT show OSD from pactl events (notifications also trigger source changes)
                            -- OSD only shows from explicit user actions (F20, XF86AudioMicMute, widget click)
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

local awful = require('awful')
local gears = require('gears')
local wibox = require('wibox')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')
local spawn = require('awful.spawn')

local osd_header = wibox.widget {
    text = 'Brightness',
    font = 'Hack Nerd Bold 14',
    align = 'left',
    valign = 'center',
    widget = wibox.widget.textbox
}

local osd_value = wibox.widget {
    text = '0%',
    font = 'Hack Nerd Bold 14',
    align = 'center',
    valign = 'center',
    widget = wibox.widget.textbox
}

local slider_osd = wibox.widget {
    nil,
    {
        id                  = 'bri_osd_slider',
        bar_shape           = gears.shape.rounded_rect,
        bar_height          = dpi(24),
        bar_color           = beautiful.groups_bg,
        bar_active_color    = beautiful.fg_focus,
        handle_color        = beautiful.fg_focus,
        handle_shape        = gears.shape.circle,
        handle_width        = dpi(24),
        handle_border_color = beautiful.background,
        handle_border_width = dpi(1),
        maximum             = 100,
        widget              = wibox.widget.slider
    },
    nil,
    expand = 'none',
    layout = wibox.layout.align.vertical
}

local bri_osd_slider = slider_osd.bri_osd_slider

bri_osd_slider:connect_signal(
    'property::value',
    function()
        local brightness_level = bri_osd_slider:get_value()
        spawn('light -S ' .. math.max(brightness_level, 5), false)

        -- Update textbox widget text
        osd_value.text = brightness_level .. '%'

        -- Update the brightness slider if values here change
        awesome.emit_signal('widget::brightness:update', brightness_level)

        if awful.screen.focused().show_bri_osd then
            awesome.emit_signal(
                'module::brightness_osd:show',
                true
            )
        end
    end
)

bri_osd_slider:connect_signal(
    'button::press',
    function()
        awful.screen.focused().show_bri_osd = true
    end
)

bri_osd_slider:connect_signal(
    'mouse::enter',
    function()
        awful.screen.focused().show_bri_osd = true
    end
)

-- The emit will come from brightness slider
awesome.connect_signal(
    'module::brightness_osd',
    function(brightness)
        bri_osd_slider:set_value(brightness)
    end
)

local icon = wibox.widget {
    {
        image = icons.brightness,
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
        s.show_bri_osd = false

        s.brightness_osd_overlay = awful.popup {
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

        s.brightness_osd_overlay:setup {
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
        s.brightness_osd_overlay:connect_signal(
            'button::press',
            function(_, _, _, button)
                if button == 3 then
                    s.brightness_osd_overlay.visible = false
                    s.show_bri_osd = false
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
        focused.brightness_osd_overlay.visible = false
        focused.show_bri_osd = false
    end
}

awesome.connect_signal(
    'module::brightness_osd:rerun',
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
    local brightness_osd = focused.brightness_osd_overlay
    awful.placement.bottom(
        brightness_osd,
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
    'module::brightness_osd:show',
    function(bool)
        placement_placer()
        awful.screen.focused().brightness_osd_overlay.visible = bool
        if bool then
            awesome.emit_signal('module::brightness_osd:rerun')
            awesome.emit_signal(
                'module::kbd_brightness_osd:show',
                false
            )
            awesome.emit_signal(
                'module::volume_osd:show',
                false
            )
        else
            if hide_osd.started then
                hide_osd:stop()
            end
        end
    end
)

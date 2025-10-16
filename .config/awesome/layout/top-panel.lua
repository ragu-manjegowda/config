local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local task_list = require('widget.task-list')
local tag_list = require('widget.tag-list')
local vseparator = require('widget.vseparator')

local top_panel = function(s)
    -- Use DPI-scaled panel height for consistency across resolutions
    -- Base height of 46px scales with DPI (at 144 DPI = ~68px)
    local panel_height = dpi(46)

    local panel = wibox
        {
            ontop = true,
            screen = s,
            type = 'desktop',
            height = panel_height,
            width = s.geometry.width,
            x = s.geometry.x,
            y = s.geometry.y,
            stretch = false,
            bg = "#0000", -- fake transparency (uses wallpaper as background)
            fg = beautiful.fg_normal
        }

    panel:struts
    {
        top = panel_height
    }

    panel:connect_signal(
        'mouse::enter',
        function()
            local w = mouse.current_wibox
            if w then
                w.cursor = 'left_ptr'
            end
        end
    )

    -- Systray can only be shown on ONE screen at a time (X11 limitation)
    -- Show on non-primary screen if available (external monitor), otherwise primary
    local systray_screen = s

    if screen.count() > 1 and s ~= screen.primary then
        systray_screen = s  -- Show on external monitor
    elseif screen.count() == 1 then
        systray_screen = s  -- Show on the only screen available
    else
        systray_screen = nil  -- Don't show on laptop screen when external is connected
    end

    s.systray = wibox.widget {
        base_size = dpi(24),  -- DPI-scaled icon size (24 @ 96 DPI, 36 @ 144 DPI)
        visible = true,
        horizontal = true,
        screen = systray_screen,
        widget = wibox.widget.systray
    }

    s.clock                   = require('widget.clock')()
    local layout_box          = require('widget.layoutbox')(s)
    s.tray_toggler            = require('widget.tray-toggle')()
    s.screen_rec              = require('widget.screen-recorder')()
    s.playerctl_center_toggle = require('widget.playerctl-center-toggle')()
    s.battery                 = require('widget.battery')()
    s.control_center_toggle   = require('widget.control-center-toggle')()
    s.info_center_toggle      = require('widget.info-center-toggle')()

    -- local taglist             = require('widget.tag-list-rubato')(s)

    panel:setup {
        {
            layout = wibox.layout.align.horizontal,
            expand = 'none',
            {
                {
                    type = 'dock',
                    layout = wibox.layout.fixed.horizontal,
                    {
                        {
                            layout = wibox.layout.fixed.horizontal,
                            -- taglist,
                            tag_list.create(s),
                        },
                        bg = beautiful.accent,
                        shape = gears.shape.rounded_rect,
                        widget = wibox.container.background,
                    },
                    vseparator,
                    {
                        {
                            {
                                layout = wibox.layout.fixed.horizontal,
                                task_list(s),
                            },
                            bg = beautiful.accent,
                            shape = gears.shape.rounded_rect,
                            widget = wibox.container.background,
                        },
                        right = dpi(7),
                        widget = wibox.container.margin,
                    },
                },

                bg = '#0000',
                shape = gears.shape.rounded_rect,
                widget = wibox.container.background,
            },
            {
                {
                    type = 'dock',
                    layout = wibox.layout.fixed.horizontal,
                    s.clock,
                },

                bg = beautiful.groups_bg,
                shape = gears.shape.rounded_rect,
                widget = wibox.container.background,
            },
            {
                {
                    type = 'dock',
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(5),
                    {
                        s.systray,
                        margins = dpi(5),
                        widget = wibox.container.margin
                    },
                    s.tray_toggler,
                    s.screen_rec,
                    s.playerctl_center_toggle,
                    s.battery,
                    s.control_center_toggle,
                    layout_box,
                    s.info_center_toggle
                },

                bg = beautiful.groups_bg,
                fg = beautiful.fg_normal,
                shape = gears.shape.rounded_rect,
                widget = wibox.container.background,
            },
        },
        left = dpi(10),
        right = dpi(10),
        top = dpi(10),
        widget = wibox.container.margin,
    }

    return panel
end

return top_panel

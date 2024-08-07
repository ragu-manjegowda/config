local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local task_list = require('widget.task-list')
local tag_list = require('widget.tag-list')
local vseparator = require('widget.vseparator')

local top_panel = function(s)
    local panel = wibox
        {
            ontop = true,
            screen = s,
            type = 'desktop',
            height = s.geometry.height / 26,
            width = s.geometry.width,
            x = s.geometry.x,
            y = s.geometry.y,
            stretch = false,
            bg = "#0000", -- fake transparency (uses wallpaper as background)
            fg = beautiful.fg_normal
        }

    panel:struts
    {
        top = s.geometry.height / 26
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

    s.systray                 = wibox.widget {
        base_size = s.geometry.width / 65,
        visible = true,
        horizontal = true,
        screen = 'primary',
        widget = wibox.widget.systray
    }

    s.clock                   = require('widget.clock')()
    local layout_box          = require('widget.layoutbox')(s)
    s.tray_toggler            = require('widget.tray-toggle')
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

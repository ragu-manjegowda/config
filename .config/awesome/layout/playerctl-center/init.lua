local awful            = require('awful')
local wibox            = require('wibox')
local gears            = require('gears')
local beautiful        = require('beautiful')
local dpi              = beautiful.xresources.apply_dpi

PANEL_VISIBLE          = false

local playerctl_center = function(s)
    -- Set the playerctl center geometry
    local panel_width = s.geometry.width / 6

    local panel       = awful.popup {
        widget         = {
            {
                {
                    {
                        {
                            require("widget.playerctl"),
                            margins = dpi(10),
                            widget = wibox.container.margin,
                        },
                        shape = function(cr, width, height)
                            gears.shape.partially_rounded_rect(
                                cr, width, height, true, true, true, true,
                                beautiful.groups_radius)
                        end,
                        bg = beautiful.groups_bg,
                        widget = wibox.container.background,
                    },
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(10),
                },
                margins = dpi(16),
                widget = wibox.container.margin
            },
            id = 'playerctl_center',
            bg = beautiful.background,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
            end,
            widget = wibox.container.background
        },
        screen         = s,
        type           = 'dock',
        visible        = false,
        ontop          = true,
        width          = dpi(panel_width),
        maximum_width  = dpi(panel_width),
        maximum_height = dpi(s.geometry.height - 38),
        bg             = beautiful.transparent,
        fg             = beautiful.fg_normal,
        shape          = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
    }

    awful.placement.top_right(
        panel,
        {
            honor_workarea = true,
            parent         = s,
            margins        = {
                top = (s.geometry.height / 22) + 10,
                right = dpi(10)
            }
        }
    )

    panel.opened = false

    s.backdrop_playerctl_center = wibox {
        ontop  = true,
        screen = s,
        bg     = beautiful.transparent,
        type   = 'utility',
        x      = s.geometry.x,
        y      = s.geometry.y,
        width  = s.geometry.width,
        height = s.geometry.height
    }

    local open_panel = function()
        local focused                             = awful.screen.focused()
        PANEL_VISIBLE                             = true

        focused.backdrop_playerctl_center.visible = true
        focused.playerctl_center.visible          = true

        panel:emit_signal('opened')
    end

    local close_panel = function()
        local focused                             = awful.screen.focused()
        PANEL_VISIBLE                             = false

        focused.playerctl_center.visible          = false
        focused.backdrop_playerctl_center.visible = false

        panel:emit_signal('closed')
    end

    -- Hide this panel when app dashboard is called.
    function panel:hide_dashboard()
        close_panel()
    end

    function panel:toggle()
        self.opened = not self.opened
        if self.opened then
            open_panel()
        else
            close_panel()
        end
    end

    s.backdrop_playerctl_center:buttons(
        awful.util.table.join(
            awful.button(
                {},
                1,
                nil,
                function()
                    panel:toggle()
                end
            )
        )
    )

    return panel
end

return playerctl_center

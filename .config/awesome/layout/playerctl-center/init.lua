local awful            = require('awful')
local wibox            = require('wibox')
local gears            = require('gears')
local beautiful        = require('beautiful')
local center_backdrop  = require('layout.center-backdrop')
local center_manager   = require('layout.center-manager')
local center_geometry  = require('layout.center-geometry')
local dpi              = beautiful.xresources.apply_dpi

local playerctl_center = function(s)
    -- Set the playerctl center geometry
    local panel_width = center_geometry.width(s)

    local panel       = awful.popup {
        widget        = {
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
        screen        = s,
        type          = 'dock',
        visible       = false,
        ontop         = true,
        width         = panel_width,
        maximum_width = panel_width,
        bg            = beautiful.transparent,
        fg            = beautiful.fg_normal,
        shape         = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
    }

    center_geometry.bind(panel, s, 'top_right')

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
        center_manager.open(panel)
        panel.opened = true
        center_backdrop.show(s.backdrop_playerctl_center, s)
        panel.visible = true

        panel:emit_signal('opened')
    end

    local close_panel = function()
        panel.opened = false
        panel.visible = false
        s.backdrop_playerctl_center.visible = false
        center_manager.close(panel)

        panel:emit_signal('closed')
    end

    -- Hide this panel when app dashboard is called.
    function panel:hide_dashboard()
        close_panel()
    end

    function panel:toggle()
        if self.opened then
            close_panel()
        else
            open_panel()
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

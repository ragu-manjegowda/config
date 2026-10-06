local awful           = require('awful')
local wibox           = require('wibox')
local gears           = require('gears')
local beautiful       = require('beautiful')
local center_backdrop = require('layout.center-backdrop')
local center_manager  = require('layout.center-manager')
local center_geometry = require('layout.center-geometry')
local dpi             = beautiful.xresources.apply_dpi

--- Date
local hours           = wibox.widget.textclock("%I")
local minutes         = wibox.widget.textclock("%M")

local date            = {
    font   = beautiful.font_bold(18),
    align  = "center",
    valign = "center",
    widget = wibox.widget.textclock("%A %B %d"),
}

local make_little_dot = function()
    return wibox.widget({
        bg            = beautiful.accent,
        forced_width  = dpi(5),
        forced_height = dpi(5),
        shape         = gears.shape.circle,
        widget        = wibox.container.background,
    })
end

local time            = {
    {
        font   = beautiful.font_bold(24),
        align  = "right",
        valign = "top",
        widget = hours,
    },
    {
        nil,
        {
            make_little_dot(),
            make_little_dot(),
            spacing = dpi(10),
            widget = wibox.layout.fixed.vertical,
        },
        expand = "none",
        widget = wibox.layout.align.vertical,
    },
    {
        font   = beautiful.font_bold(24),
        align  = "left",
        valign = "top",
        widget = minutes,
    },
    spacing = dpi(20),
    layout  = wibox.layout.fixed.horizontal,
}

local calendar_center = function(s)
    local panel = awful.popup {
        widget  = {
            {
                {
                    {
                        {
                            {
                                spacing = dpi(10),
                                {
                                    nil,
                                    time,
                                    expand = "none",
                                    layout = wibox.layout.align.horizontal,
                                },
                                date,
                                layout = wibox.layout.fixed.vertical,
                            },
                            margins = dpi(10),
                            widget = wibox.container.margin,
                        },
                        bg = beautiful.groups_bg,
                        widget = wibox.container.background,
                        shape = function(cr, width, height)
                            gears.shape.partially_rounded_rect(
                                cr, width, height, true, true, true, true,
                                beautiful.groups_radius)
                        end,
                    },
                    {
                        {
                            require("widget.calendar"),
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
            id = 'calendar_center',
            bg = beautiful.background,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
            end,
            widget = wibox.container.background
        },
        screen  = s,
        type    = 'dock',
        visible = false,
        ontop   = true,
        bg      = beautiful.transparent,
        fg      = beautiful.fg_normal,
        shape   = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
    }

    center_geometry.bind(panel, s, 'top', true)

    panel.opened = false

    s.backdrop_calendar_center = wibox {
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
        local calendar = require('widget.calendar')
        if calendar.set_input_owner then calendar:set_input_owner(panel) end
        panel.opened = true
        center_backdrop.show(s.backdrop_calendar_center, s)
        panel.visible = true

        panel:emit_signal('opened')
    end

    local close_panel = function()
        local calendar = require('widget.calendar')
        if calendar.stop_prompt then calendar:stop_prompt() end
        panel.opened = false
        panel.visible = false
        s.backdrop_calendar_center.visible = false
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
            require("widget.calendar"):update()
            open_panel()
        end
    end

    s.backdrop_calendar_center:buttons(
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

return calendar_center

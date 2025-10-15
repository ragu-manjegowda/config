local wibox = require("wibox")
local awful = require('awful')
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local gears = require('gears')
local clickable_container = require('widget.clickable-container')

--- Clock Widget
--- ~~~~~~~~~~~~

return function()
    local clock = wibox.widget({
        widget = wibox.widget.textclock,
        format = "%a %b %d %l:%M %p",
        align = "center",
        valign = "center",
        font = beautiful.font_bold(12),
    })

    clock.markup = "<span foreground='" .. beautiful.fg_normal .. "'>" .. clock.text .. "</span>"
    clock:connect_signal("widget::redraw_needed", function()
        clock.markup = "<span foreground='" .. beautiful.fg_normal .. "'>" .. clock.text .. "</span>"
    end)

    local widget_button = wibox.widget {
        {
            clock,
            margins = dpi(5),
            widget = wibox.container.margin
        },
        widget = clickable_container
    }

    widget_button:buttons(
        gears.table.join(
            awful.button(
                {},
                1,
                nil,
                function()
                    awful.screen.focused().calendar_center:toggle()
                end
            )
        )
    )

    return widget_button
end

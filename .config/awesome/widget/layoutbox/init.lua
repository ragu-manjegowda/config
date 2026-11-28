local wibox = require('wibox')
local symbolic = require('theme.symbolic')
local awful = require('awful')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')

local layout_box = function(s)
    local indicator = awful.widget.layoutbox { screen = s }
    symbolic.attach(indicator.imagebox)
    local layoutbox = wibox.widget {
        {
            indicator,
            margins = dpi(7),
            widget = wibox.container.margin
        },
        widget = clickable_container
    }
    layoutbox:buttons(
        awful.util.table.join(
            awful.button(
                {},
                1,
                function()
                    awful.layout.inc(1)
                end
            ),
            awful.button(
                {},
                3,
                function()
                    awful.layout.inc(-1)
                end
            ),
            awful.button(
                {},
                4,
                function()
                    awful.layout.inc(1)
                end
            ),
            awful.button(
                {},
                5,
                function()
                    awful.layout.inc(-1)
                end
            )
        )
    )
    return layoutbox
end

return layout_box

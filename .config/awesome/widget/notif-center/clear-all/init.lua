local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')

local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')

local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/notif-center/icons/'

local function new_clear_all_button()
    local clear_all_button = wibox.widget {
        {
            {
                image = widget_icon_dir .. 'clear_all.svg',
                resize = true,
                forced_height = dpi(17),
                forced_width = dpi(17),
                widget = wibox.widget.imagebox,
            },
            layout = wibox.layout.fixed.horizontal
        },
        margins = dpi(5),
        widget = wibox.container.margin
    }
    clear_all_button = wibox.widget {
        clear_all_button,
        widget = clickable_container
    }
    clear_all_button:buttons(
        gears.table.join(
            awful.button({}, 1, nil, function()
                awesome.emit_signal('widget::notif-center:clear_all')
            end)
        )
    )

    return wibox.widget {
        nil,
        {
            clear_all_button,
            bg = beautiful.accent,
            shape = gears.shape.circle,
            widget = wibox.container.background
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    }
end

return new_clear_all_button

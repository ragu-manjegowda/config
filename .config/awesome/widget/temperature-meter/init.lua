local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')
local cpu_temperature = require('library.cpu-temperature')

local meter_name = wibox.widget {
    text = 'Temperature',
    font = beautiful.font_bold(10),
    align = 'left',
    widget = wibox.widget.textbox
}

local icon = wibox.widget {
    layout = wibox.layout.align.vertical,
    expand = 'none',
    nil,
    {
        image = icons.thermometer,
        resize = true,
        widget = wibox.widget.imagebox
    },
    nil
}

local meter_icon = wibox.widget {
    {
        icon,
        margins = dpi(5),
        widget = wibox.container.margin
    },
    bg = beautiful.groups_bg,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
    end,
    widget = wibox.container.background
}

local slider = wibox.widget {
    nil,
    {
        id               = 'temp_status',
        max_value        = 100,
        value            = 29,
        forced_height    = dpi(24),
        color            = beautiful.fg_focus,
        background_color = beautiful.background,
        shape            = gears.shape.rounded_rect,
        widget           = wibox.widget.progressbar
    },
    nil,
    expand = 'none',
    forced_height = dpi(36),
    layout = wibox.layout.align.vertical
}

local max_temp = 100
local temp_t

local function update_temperature()
    temp_t = cpu_temperature.read()
    slider.temp_status.visible = temp_t ~= nil
    if temp_t then
        slider.temp_status:set_value(temp_t / max_temp * 100)
    end
end

local temperature_timer = gears.timer { timeout = 10, callback = update_temperature }
awesome.connect_signal('control_center::monitor_visibility', function(visible)
    if visible then
        update_temperature()
        temperature_timer:start()
    else
        temperature_timer:stop()
    end
end)

local temp_meter = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(5),
    meter_name,
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(5),
        {
            layout = wibox.layout.align.vertical,
            expand = 'none',
            nil,
            {
                layout = wibox.layout.fixed.horizontal,
                forced_height = dpi(24),
                forced_width = dpi(24),
                meter_icon
            },
            nil
        },
        slider
    }
}

local mytempmeter_t = awful.tooltip {}

mytempmeter_t:add_to_object(temp_meter)

temp_meter:connect_signal('mouse::enter', function()
    mytempmeter_t.text = temp_t and string.format('CPU package temp = %.1f°C', temp_t) or
        'CPU package temperature unavailable'
end)

return temp_meter

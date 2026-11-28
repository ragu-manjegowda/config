local symbolic = require('theme.symbolic')
local bindings = require('theme.bindings')
local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')

local meter_name = wibox.widget {
    text = 'RAM',
    font = beautiful.font_bold(10),
    align = 'left',
    widget = wibox.widget.textbox
}

local icon = wibox.widget {
    layout = wibox.layout.align.vertical,
    expand = 'none',
    nil,
    {
        image = icons.memory,
        resize = true,
        widget = symbolic.imagebox
    },
    nil
}

local meter_icon = wibox.widget {
    {
        icon,
        margins = dpi(5),
        widget = wibox.container.margin
    },
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
    end,
    widget = bindings.widget(wibox.container.background, { bg = 'groups_bg' })
}

local slider = wibox.widget {
    nil,
    {
        id            = 'ram_usage',
        max_value     = 100,
        value         = 29,
        forced_height = dpi(24),
        shape         = gears.shape.rounded_rect,
        widget        = bindings.widget(wibox.widget.progressbar, { color = 'fg_focus', background_color = 'background' })
    },
    nil,
    expand = 'none',
    forced_height = dpi(36),
    layout = wibox.layout.align.vertical
}

local function update_ram()
    local meminfo = io.open('/proc/meminfo', 'r')
    if not meminfo then
        return
    end

    local values = {}
    for line in meminfo:lines() do
        local key, value = line:match('^(%w+):%s+(%d+)')
        if key then
            values[key] = tonumber(value)
        end
    end
    meminfo:close()

    if values.MemTotal and values.MemAvailable then
        slider.ram_usage:set_value(
            (values.MemTotal - values.MemAvailable) / values.MemTotal * 100
        )
    end
end

local ram_timer = gears.timer { timeout = 10, callback = update_ram }
awesome.connect_signal('control_center::monitor_visibility', function(visible)
    if visible then
        update_ram()
        ram_timer:start()
    else
        ram_timer:stop()
    end
end)

local ram_meter = wibox.widget {
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

local myrammeter_t = awful.tooltip {}

myrammeter_t:add_to_object(ram_meter)

ram_meter:connect_signal('mouse::enter', function()
    myrammeter_t.text = 'RAM usage = ' .. tostring(slider.ram_usage.value) .. '%'
end)

return ram_meter

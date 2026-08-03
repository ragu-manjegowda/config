local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')

local meter_name = wibox.widget {
    text = 'CPU',
    font = beautiful.font_bold(10),
    align = 'left',
    widget = wibox.widget.textbox
}

local icon = wibox.widget {
    layout = wibox.layout.align.vertical,
    expand = 'none',
    nil,
    {
        image = icons.chart,
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
        id               = 'cpu_usage',
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
    forced_height = dpi(24),
    layout = wibox.layout.align.vertical
}

local total_prev
local idle_prev

local function update_cpu()
    local stat = io.open('/proc/stat', 'r')
    if not stat then
        return
    end

    local line = stat:read('*l')
    stat:close()
    if line then
        local user, nice, system, idle, iowait, irq, softirq, steal, _, _ =
            line:match('cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)')

        if not user then
            return
        end

        local total = user + nice + system + idle + iowait + irq + softirq + steal

        if total_prev then
            local diff_idle = idle - idle_prev
            local diff_total = total - total_prev
            if diff_total > 0 then
                slider.cpu_usage:set_value(100 * (diff_total - diff_idle) / diff_total)
            end
        end

        total_prev = total
        idle_prev = idle
    end
end

local cpu_timer = gears.timer { timeout = 10, callback = update_cpu }
awesome.connect_signal('control_center::monitor_visibility', function(visible)
    if visible then
        update_cpu()
        cpu_timer:start()
    else
        cpu_timer:stop()
        total_prev = nil
        idle_prev = nil
    end
end)

local cpu_meter = wibox.widget {
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

local mycpumeter_t = awful.tooltip {}

mycpumeter_t:add_to_object(cpu_meter)

cpu_meter:connect_signal('mouse::enter', function()
    mycpumeter_t.text = 'CPU usage = ' .. tostring(slider.cpu_usage.value) .. '%'
end)

return cpu_meter

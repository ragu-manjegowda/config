local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local watch = awful.widget.watch
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')

local meter_name = wibox.widget {
    text = 'Temperature',
    font = 'Hack Nerd Bold 10',
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

local max_temp = 80

local temp_t = 0

-- TODO: line 6 and 7 needs to be fixed, this still works as we default to
-- zone0 in line 24
local cmd =
[[
	temp_path=null
	for i in /sys/class/hwmon/hwmon*/temp*_input;
	do
        #temp_path="$(echo "$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null ||
        #	echo $(basename ${i%_*})) $(readlink -f $i)");"

		label="$(echo $temp_path | awk '{print $2}')"

		if [ "$label" = "Package" ];
		then
			echo ${temp_path} | awk '{print $5}' | tr -d ';\n'
			exit;
		fi
	done
	]]

awful.spawn.easy_async_with_shell(
    cmd,
    function(stdout)
        local temp_path = stdout:gsub('%\n', '')
        if temp_path == '' or not temp_path then
            temp_path = '/sys/class/thermal/thermal_zone0/temp'
        end

        watch(
            [[
			sh -c "cat ]] .. temp_path .. [["
			]],
            10,
            function(_, stdout_)
                local temp = stdout_:match('(%d+)')
                slider.temp_status:set_value((temp / 1000) / max_temp * 100)
                temp_t = temp / 1000
                collectgarbage('collect')
            end
        )
    end
)

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
    mytempmeter_t.text = 'CPU core temp = ' .. tostring(temp_t) .. '\'C'
end)

return temp_meter

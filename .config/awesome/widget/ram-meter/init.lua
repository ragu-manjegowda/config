local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local watch = awful.widget.watch
local spawn = awful.spawn
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')

local meter_name = wibox.widget {
	text = 'RAM',
	font = 'Hack Nerd Bold 10',
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
		id 				 = 'ram_usage',
		max_value     	 = 100,
		value         	 = 29,
		forced_height 	 = dpi(24),
		color 			 = beautiful.fg_focus,
		background_color = beautiful.background,
		shape 			 = gears.shape.rounded_rect,
		widget        	 = wibox.widget.progressbar
	},
	nil,
	expand = 'none',
	forced_height = dpi(36),
	layout = wibox.layout.align.vertical
}

watch(
	'bash -c "free | grep -z Mem.*Swap.*"',
	10,
	function(_, stdout)
		local total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap =
			stdout:match('(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*Swap:%s*(%d+)%s*(%d+)%s*(%d+)')
		slider.ram_usage:set_value(used / total * 100)
		collectgarbage('collect')
	end
)

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

local myrammeter_t = awful.tooltip
{
    fg = beautiful.background,
    bg = beautiful.accent,
}

myrammeter_t:add_to_object(ram_meter)

ram_meter:connect_signal('mouse::enter', function()
    myrammeter_t.text = 'RAM usage = ' .. tostring(slider.ram_usage.value) .. '%'
end)

return ram_meter

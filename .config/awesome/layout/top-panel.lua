local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local icons = require('theme.icons')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local task_list = require('widget.task-list')
local tag_list = require('widget.tag-list')
local vseparator = require('widget.vseparator')

local top_panel = function(s)

	local panel = wibox
	{
		ontop = true,
		screen = s,
		type = 'desktop',
		height = dpi(33),
		width = s.geometry.width,
		x = s.geometry.x,
		y = s.geometry.y,
		stretch = false,
		bg = "#0000", -- fake transparency (uses wallpaper as background)
		fg = beautiful.fg_normal
	}

	panel:struts
	{
		top = dpi(33)
	}

	panel:connect_signal(
		'mouse::enter',
		function()
			local w = mouse.current_wibox
			if w then
				w.cursor = 'left_ptr'
			end
		end
	)

	s.systray = wibox.widget {
		visible = false,
		base_size = dpi(20),
		horizontal = true,
		screen = 'primary',
		widget = wibox.widget.systray
	}

	local clock 			= require('widget.clock')(s)
	local layout_box 		= require('widget.layoutbox')(s)
	s.tray_toggler  		= require('widget.tray-toggle')
	s.screen_rec 			= require('widget.screen-recorder')()
	s.battery     			= require('widget.battery')()
	s.vpn     			    = require('widget.vpn')()
	s.network       		= require('widget.network')()
	s.control_center_toggle = require('widget.control-center-toggle')()
	s.global_search			= require('widget.global-search')()
	s.info_center_toggle 	= require('widget.info-center-toggle')()

	panel : setup {
        {
	    	layout = wibox.layout.align.horizontal,
	    	expand = 'none',
	    	{
                {
	    	        type = 'dock',
	    		    layout = wibox.layout.fixed.horizontal,
                    {
                        {
	    		            layout = wibox.layout.fixed.horizontal,
                            tag_list.create(s),
                        },
                        bg = beautiful.groups_bg,
                        shape = gears.shape.rounded_rect,
                        widget = wibox.container.background,
                    },
                    vseparator,
                    {
                        {
	    		            layout = wibox.layout.fixed.horizontal,
	    		            task_list(s),
                        },
                        bg = beautiful.groups_bg,
                        shape = gears.shape.rounded_rect,
                        widget = wibox.container.background,
                    },
                },

                bg = '#0000',
                shape = gears.shape.rounded_rect,
                widget = wibox.container.background,
	    	},
            {
                {
	    	        type = 'dock',
                    layout = wibox.layout.fixed.horizontal,
                    clock,
                },

                bg = beautiful.groups_bg,
                shape = gears.shape.rounded_rect,
                widget = wibox.container.background,
            },
	    	{
                {
	    	        type = 'dock',
	    		    layout = wibox.layout.fixed.horizontal,
	    		    spacing = dpi(5),
	    		    {
	    		    	s.systray,
	    		    	margins = dpi(5),
	    		    	widget = wibox.container.margin
	    		    },
	    		    s.tray_toggler,
	    		    s.screen_rec,
	    		    s.network,
	    		    s.battery,
                    s.vpn,
	    		    s.control_center_toggle,
	    		    s.global_search,
	    		    layout_box,
	    		    s.info_center_toggle
                },

                bg = beautiful.groups_bg,
                shape = gears.shape.rounded_rect,
                widget = wibox.container.background,
	    	},
        },
        left = dpi(25),
        right = dpi(5),
        top = dpi(5),
        widget = wibox.container.margin,
	}

	return panel
end

return top_panel

local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local apps = require('configuration.apps')

local dir = os.getenv("HOME") .. "/.config/awesome/theme/icons/tags/"

local tags = {
	{
        icon = dir .. "1.png",
		gap = beautiful.useless_gap
	},
	{
        icon = dir .. "2.png",
		gap = beautiful.useless_gap
	},
	{
        icon = dir .. "3.png",
		gap = beautiful.useless_gap
	},
	{
        icon = dir .. "4.png",
		gap = beautiful.useless_gap,
	},
	{
        icon = dir .. "5.png",
		gap = beautiful.useless_gap,
	},
	{
        icon = dir .. "6.png",
		gap = beautiful.useless_gap,
	},
	{
        icon = dir .. "7.png",
		gap = beautiful.useless_gap
	},
	{
        icon = dir .. "8.png",
		gap = beautiful.useless_gap,
	},
	{
        icon = dir .. "9.png",
		gap = beautiful.useless_gap,
	}
}

-- Set tags layout
tag.connect_signal(
	'request::default_layouts',
	function()
	    awful.layout.append_default_layouts({
			awful.layout.suit.spiral.dwindle,
			awful.layout.suit.tile,
			awful.layout.suit.floating,
			awful.layout.suit.max
	    })
	end
)

-- Create tags for each screen
screen.connect_signal(
	'request::desktop_decoration',
	function(s)
		for i, tag in pairs(tags) do
			awful.tag.add(
				i,
				{
					icon = tag.icon,
                    icon_only = true,
					layout = awful.layout.suit.tile,
					gap_single_client = true,
					gap = tag.gap,
					screen = s,
					selected = i == 1
				}
			)
		end
	end
)

local update_gap_and_shape = function(t)
	-- Get current tag layout
	local current_layout = awful.tag.getproperty(t, 'layout')
	-- If the current layout is awful.layout.suit.max
	if (current_layout == awful.layout.suit.max) then
		-- Set clients gap to 0 and shape to rectangle if maximized
		t.gap = 0
		for _, c in ipairs(t:clients()) do
			if not c.floating or not c.round_corners or c.maximized or c.fullscreen then
				c.shape = beautiful.client_shape_rectangle
			else
				c.shape = beautiful.client_shape_rounded
			end
		end
	else
		t.gap = beautiful.useless_gap
		for _, c in ipairs(t:clients()) do
			if not c.round_corners or c.maximized or c.fullscreen then
				c.shape = beautiful.client_shape_rectangle
			else
				c.shape = beautiful.client_shape_rounded
			end
		end
	end
end

-- Change tag's client's shape and gap on change
tag.connect_signal(
	'property::layout',
	function(t)
		update_gap_and_shape(t)
	end
)

-- Change tag's client's shape and gap on move to tag
tag.connect_signal(
	'tagged',
	function(t)
		update_gap_and_shape(t)
	end
)

-- Focus on urgent clients
awful.tag.attached_connect_signal(
	s,
	'property::selected',
	function()
		local urgent_clients = function (c)
			return awful.rules.match(c, {urgent = true})
		end
		for c in awful.client.iterate(urgent_clients) do
			if c.first_tag == mouse.screen.selected_tag then
				c:emit_signal('request::activate')
				c:raise()
			end
		end
	end
)

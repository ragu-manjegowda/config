local awful = require('awful')
local gears = require('gears')
local dpi = require('beautiful').xresources.apply_dpi
require('awful.autofocus')
local modkey = require('configuration.keys.mod').mod_key
local altkey = require('configuration.keys.mod').alt_key

local client_keys = awful.util.table.join(
	awful.key(
		{modkey, 'Control'},
		'c',
		function(c)
			local focused = awful.screen.focused()

			awful.placement.centered(c, {
				honor_workarea = true
			})
		end,
		{description = 'align a client to the center of the focused screen', group = 'client'}
	),
	awful.key(
		{modkey},
		'f',
		function(c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end,
		{description = 'toggle fullscreen', group = 'client'}
	),
    -- Focus client by direction (hjkl keys)
    awful.key(
        {modkey},
        'h',
        function()
            awful.client.focus.bydirection("left")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus left", group = "client"}
    ),
    awful.key(
        {modkey},
       'j',
        function()
            awful.client.focus.bydirection("down")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus down", group = "client"}
    ),
    awful.key(
        {modkey},
        'k',
        function()
            awful.client.focus.bydirection("up")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus up", group = "client"}
    ),
    awful.key(
        { modkey },
        'l',
        function()
            awful.client.focus.bydirection("right")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus right", group = "client"}
    ),
    awful.key(
        {modkey},
        'm',
        function (c)
		    --if c.maximized then
	        c.maximized = not c.maximized
	        c:raise()
        end,
        {description = "maximize", group = "client"}
    ),
    awful.key(
        {modkey},
        'n',
        function(c)
            c.minimized = true
        end,
        {description = 'minimize client', group = 'client'}
    ),
    awful.key(
		{modkey, 'Shift'},
		'n',
		function()
			local c = awful.client.restore()
			-- Focus restored client
			if c then
				c:emit_signal('request::activate')
				c:raise()
			end
		end,
		{description = 'restore minimized', group = 'client'}
	),
	awful.key(
		{modkey},
		'o',
		function()
			awful.tag.incgap(1)
		end,
		{description = 'increase gap', group = 'client'}
	),
	awful.key(
		{modkey, 'Shift'},
		'o',
		function()
			awful.tag.incgap(-1)
		end,
		{description = 'decrease gap', group = 'client'}
	),
	awful.key(
		{modkey},
		'p',
		awful.tag.history.restore,
		{description = 'alternate between current and previous tag', group = 'client'}
	),
	awful.key(
		{modkey},
		'q',
		function(c)
			c:kill()
		end,
		{description = 'close', group = 'client'}
	),
	awful.key(
		{modkey},
		'u',
		awful.client.urgent.jumpto,
		{description = 'jump to urgent client', group = 'client'}
	),

	awful.key(
		{modkey},
		'Up',
		function(c)
			c:relative_move(0, dpi(-10), 0, 0)
		end,
		{description = 'move floating client up by 10 px', group = 'client'}
	),
	awful.key(
		{modkey},
		'Down',
		function(c)
			c:relative_move(0, dpi(10), 0, 0)
		end,
		{description = 'move floating client down by 10 px', group = 'client'}
	),
	awful.key(
		{modkey},
		'Left',
		function(c)
			c:relative_move(dpi(-10), 0, 0, 0)
		end,
		{description = 'move floating client to the left by 10 px', group = 'client'}
	),
	awful.key(
		{modkey},
		'Right',
		function(c)
			c:relative_move(dpi(10), 0, 0, 0)
		end,
		{description = 'move floating client to the right by 10 px', group = 'client'}
	),
	awful.key(
		{modkey, 'Shift'},
		'Up',
		function(c)
			c:relative_move(0, dpi(-10), 0, dpi(10))
		end,
		{description = 'increase floating client size vertically by 10 px up', group = 'client'}
	),
	awful.key(
		{modkey, 'Shift'},
		'Down',
		function(c)
			c:relative_move(0, 0, 0, dpi(10))
		end,
		{description = 'increase floating client size vertically by 10 px down', group = 'client'}
	),
	awful.key(
		{modkey, 'Shift'},
		'Left',
		function(c)
			c:relative_move(dpi(-10), 0, dpi(10), 0)
		end,
		{description = 'increase floating client size horizontally by 10 px left', group = 'client'}
	),
	awful.key(
		{modkey, 'Shift'},
		'Right',
		function(c)
			c:relative_move(0, 0, dpi(10), 0)
		end,
		{description = 'increase floating client size horizontally by 10 px right', group = 'client'}
	),
	awful.key(
		{modkey, 'Control'},
		'Up',
		function(c)
			if c.height > 10 then
				c:relative_move(0, 0, 0, dpi(-10))
			end
		end,
		{description = 'decrease floating client size vertically by 10 px up', group = 'client'}
	),
	awful.key(
		{modkey, 'Control'},
		'Down',
		function(c)
			local c_height = c.height
			c:relative_move(0, 0, 0, dpi(-10))
			if c.height ~= c_height and c.height > 10 then
				c:relative_move(0, dpi(10), 0, 0)
			end
		end,
		{description = 'decrease floating client size vertically by 10 px down', group = 'client'}
	),
	awful.key(
		{modkey, 'Control'},
		'Left',
		function(c)
			if c.width > 10 then
				c:relative_move(0, 0, dpi(-10), 0)
			end
		end,
		{description = 'decrease floating client size horizontally by 10 px left', group = 'client'}
	),
	awful.key(
		{modkey, 'Control'},
		'Right',
		function(c)
			local c_width = c.width
			c:relative_move(0, 0, dpi(-10), 0)
			if c.width ~= c_width and c.width > 10 then
				c:relative_move(dpi(10), 0 , 0, 0)
			end
		end,
		{description = 'decrease floating client size horizontally by 10 px right', group = 'client'}
	)
)

return client_keys

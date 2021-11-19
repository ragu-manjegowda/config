local awful = require('awful')
local gears = require('gears')
local dpi = require('beautiful').xresources.apply_dpi
require('awful.autofocus')
local modkey = require('configuration.keys.mod').mod_key
local altkey = require('configuration.keys.mod').alt_key

-- Resize client in given direction
local floating_resize_amount = dpi(20)
local tiling_resize_factor = 0.05

local function resize_client(c, key, direction)
    if awful.layout.get(mouse.screen) == awful.layout.suit.floating or (c and c.floating) then
        if key == "Shift" then -- increase
            if direction == "up" then
                c:relative_move(0, -floating_resize_amount, 0, floating_resize_amount)
            elseif direction == "down" then
                c:relative_move(0, 0, 0, floating_resize_amount)
            elseif direction == "left" then
                c:relative_move(-floating_resize_amount, 0, floating_resize_amount, 0)
            elseif direction == "right" then
                c:relative_move(0, 0, floating_resize_amount, 0)
            end
        elseif key == "Control" then -- decrease
            if direction == "up" then
			    if c.height > 10 then
                    c:relative_move(0, 0, 0, -floating_resize_amount)
			    end
            elseif direction == "down" then
			    local c_height = c.height
			    c:relative_move(0, 0, 0, -floating_resize_amount)
			    if c.height ~= c_height and c.height > 10 then
			    	c:relative_move(0, floating_resize_amount, 0, 0)
			    end
            elseif direction == "left" then
			    if c.width > 10 then
			    	c:relative_move(0, 0, -floating_resize_amount, 0)
			    end
            elseif direction == "right" then
			    local c_width = c.width
			    c:relative_move(0, 0, -floating_resize_amount, 0)
			    if c.width ~= c_width and c.width > 10 then
			    	c:relative_move(floating_resize_amount, 0 , 0, 0)
			    end
            end
        end
    else
        if direction == "up" then
            awful.client.incwfact(-tiling_resize_factor)
        elseif direction == "down" then
            awful.client.incwfact(tiling_resize_factor)
        elseif direction == "left" then
            awful.tag.incmwfact(-tiling_resize_factor)
        elseif direction == "right" then
            awful.tag.incmwfact(tiling_resize_factor)
        end
    end
end

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
		{modkey, 'Control'},
		'p',
		function()
			awful.client.focus.history.previous()
			if client.focus then
				client.focus:raise()
			end
		end,
		{description = 'go to previous client', group = 'client'}
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
		'Tab',
		function()
			awful.client.focus.byidx(1)
		end,
		{description = 'focus next by index', group = 'client'}
	),
	awful.key(
		{modkey, 'Shift'},
		'Tab',
		function()
			awful.client.focus.byidx(-1)
		end,
		{description = 'focus previous by index', group = 'client'}
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
            resize_client(client.focus, "Shift", "up")
		end,
		{description = 'increase client size vertically by 20 px up', group = 'client'}
	),
	awful.key(
		{modkey, 'Shift'},
		'Down',
		function(c)
            resize_client(client.focus, "Shift", "down")
		end,
		{description = 'increase client size vertically by 20 px down', group = 'client'}
	),
	awful.key(
		{modkey, 'Shift'},
		'Left',
		function(c)
            resize_client(client.focus, "Shift", "left")
		end,
		{description = 'increase client size horizontally by 20 px left', group = 'client'}
	),
	awful.key(
		{modkey, 'Shift'},
		'Right',
		function(c)
            resize_client(client.focus, "Shift", "right")
		end,
		{description = 'increase client size horizontally by 20 px right', group = 'client'}
	),
	awful.key(
		{modkey, 'Control'},
		'Up',
		function(c)
            resize_client(client.focus, "Control", "up")
		end,
		{description = 'decrease client size vertically by 20 px up', group = 'client'}
	),
	awful.key(
		{modkey, 'Control'},
		'Down',
		function(c)
            resize_client(client.focus, "Control", "down")
		end,
		{description = 'decrease client size vertically by 20 px down', group = 'client'}
	),
	awful.key(
		{modkey, 'Control'},
		'Left',
		function(c)
            resize_client(client.focus, "Control", "left")
		end,
		{description = 'decrease client size horizontally by 20 px left', group = 'client'}
	),
	awful.key(
		{modkey, 'Control'},
		'Right',
		function(c)
            resize_client(client.focus, "Control", "right")
		end,
		{description = 'decrease client size horizontally by 20 px right', group = 'client'}
	)
)

return client_keys

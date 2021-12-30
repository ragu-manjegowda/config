local awful = require('awful')
local beautiful = require('beautiful')
local naughty = require("naughty")

require('awful.autofocus')

local hotkeys_popup = require('awful.hotkeys_popup').widget.new({
        width = 2500, height = 1350})

local modkey = require('configuration.keys.mod').mod_key
local altkey = require('configuration.keys.mod').alt_key
local apps = require('configuration.apps')

-- Key bindings
local global_keys = awful.util.table.join(

	-- Hotkeys
	awful.key(
		{modkey},
		'a',
		function()
			local focused = awful.screen.focused()

			if focused.control_center then
				focused.control_center:hide_dashboard()
				focused.control_center.opened = false
			end
			if focused.info_center then
				focused.info_center:hide_dashboard()
				focused.info_center.opened = false
			end
			awful.spawn(apps.default.rofi_appmenu, false)
		end,
		{description = 'open application drawer', group = 'launcher'}
	),

    awful.key(
		{modkey},
		'b',
		function()
			awesome.emit_signal('widget::blue_light:toggle')
		end,
		{description = 'toggle redshift filter', group = 'Utility'}
	),

	awful.key(
		{modkey},
		'c',
		function()
			local focused = awful.screen.focused()
			if focused.info_center and focused.info_center.visible then
				focused.info_center:toggle()
			end
			focused.control_center:toggle()
		end,
		{description = 'open control center', group = 'launcher'}
	),

	awful.key(
		{modkey},
		'd',
		function()
            naughty.destroy_all_notifications()
		end,
		{description = 'Destroy all notifications', group = 'launcher'}
	),

	awful.key(
		{modkey},
		'e',
		function()
			awful.spawn("rofi -show run")
		end,
		{description = 'Rofi run menu', group = 'launcher'}
	),

	awful.key(
		{modkey},
		'g',
		function()
			awful.spawn(apps.default.web_browser)
		end,
		{description = 'open Firefox web browser', group = 'launcher'}
	),

	awful.key(
		{modkey},
		'i',
		function()
			local focused = awful.screen.focused()
			if focused.control_center and focused.control_center.visible then
				focused.control_center:toggle()
			end
			focused.info_center:toggle()
		end,
		{description = 'open info center', group = 'launcher'}
	),

    awful.key(
		{modkey, 'Control'},
		'l',
		function()
			awful.spawn(apps.default.lock, false)
		end,
		{description = 'lock the screen', group = 'launcher'}
	),

    awful.key(
		{modkey, 'Control'},
		'n',
		function()
			local focused = awful.screen.focused()
			if focused.info_center and focused.info_center.visible then
			    awesome.emit_signal('widget::notif-center:clear_all')
			end
		end,
		{description = 'clear notifications', group = 'launcher'}
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
		'p',
		awful.tag.history.restore,
		{description = 'alternate between current and previous tag', group = 'tag'}
	),

	awful.key(
		{ },
		'Print',
		function ()
			awful.spawn.easy_async_with_shell(apps.utils.full_screenshot,function() end)
		end,
		{description = 'fullscreen screenshot', group = 'Utility'}
	),

	awful.key(
		{'Shift'},
		'Print',
		function ()
			awful.spawn.easy_async_with_shell(apps.utils.area_screenshot,function() end)
		end,
		{description = 'area/selected screenshot', group = 'Utility'}
	),

	awful.key(
		{modkey, 'Control'},
		'q',
		function()
			awesome.emit_signal('module::exit_screen:show')
		end,
		{description = 'toggle exit screen', group = 'launcher'}
	),

    awful.key(
		{modkey},
		'r',
		function()
			awful.spawn(apps.default.terminal .. " --class ranger -e /home/linuxbrew/.linuxbrew/bin/ranger")
		end,
		{description = 'open default file manager', group = 'launcher'}
	),

	awful.key(
        {modkey, 'Control'},
		'r',
		awesome.restart,
		{description = 'reload awesome', group = 'awesome'}
	),

    awful.key(
		{modkey},
		'Return',
		function()
			awful.spawn(apps.default.terminal .. " --class terminal_no_title")
		end,
		{description = 'open default terminal', group = 'launcher'}
	),

	awful.key(
		{modkey},
		's',
        function()
            hotkeys_popup:show_help(nil, awful.screen.focused())
        end,
		{description = 'show help', group = 'awesome'}
	),

	awful.key(
		{modkey, 'Control'},
		's',
		function()
			awful.spawn(apps.default.rofi_global, false)
		end,
		{description = 'open global search', group = 'launcher'}
	),

	awful.key(
		{modkey},
		'space',
		function()
			awful.layout.inc(1)
		end,
		{description = 'select next layout', group = 'awesome'}
	),

	awful.key(
		{modkey, 'Shift'},
		'space',
		function()
			awful.layout.inc(-1)
		end,
		{description = 'select previous layout', group = 'awesome'}
	),

	awful.key(
		{modkey},
		't',
		function()
			awesome.emit_signal('widget::blur:toggle')
		end,
		{description = 'toggle blur effects', group = 'Utility'}
	),

	awful.key(
		{modkey},
		'u',
		awful.client.urgent.jumpto,
		{description = 'jump to urgent client', group = 'client'}
	),

    awful.key(
		{modkey},
		'w',
		function ()
			if screen.primary.systray then
				if not screen.primary.tray_toggler then
					local systray = screen.primary.systray
					systray.visible = not systray.visible
				else
					awesome.emit_signal('widget::systray:toggle')
				end
			end
		end,
		{description = 'toggle systray visibility', group = 'Utility'}
	),

    awful.key(
		{modkey},
		']',
		function()
			awesome.emit_signal('widget::blur:increase')
		end,
		{description = 'increase blur effect by 10%', group = 'Utility'}
	),

	awful.key(
		{modkey},
		'[',
		function()
			awesome.emit_signal('widget::blur:decrease')
		end,
		{description = 'decrease blur effect by 10%', group = 'Utility'}
	),

	awful.key(
		{},
		'XF86MonBrightnessUp',
		function()
			awful.spawn('light -A 10', false)
			awesome.emit_signal('widget::brightness')
			awesome.emit_signal('module::brightness_osd:show', true)
		end,
		{description = 'increase brightness by 10%', group = 'hotkeys'}
	),

	awful.key(
		{},
		'XF86MonBrightnessDown',
		function()
			awful.spawn('light -U 10', false)
			awesome.emit_signal('widget::brightness')
			awesome.emit_signal('module::brightness_osd:show', true)
		end,
		{description = 'decrease brightness by 10%', group = 'hotkeys'}
	),

	-- ALSA volume control
	awful.key(
		{},
		'XF86AudioRaiseVolume',
		function()
			awful.spawn('amixer -D pulse sset Master 5%+', false)
			awesome.emit_signal('widget::volume')
			awesome.emit_signal('module::volume_osd:show', true)
		end,
		{description = 'increase volume up by 5%', group = 'hotkeys'}
	),

	awful.key(
		{},
		'XF86AudioLowerVolume',
		function()
			awful.spawn('amixer -D pulse sset Master 5%-', false)
			awesome.emit_signal('widget::volume')
			awesome.emit_signal('module::volume_osd:show', true)
		end,
		{description = 'decrease volume up by 5%', group = 'hotkeys'}
	),

	awful.key(
		{},
		'XF86AudioMute',
		function()
			awful.spawn('amixer -D pulse set Master 1+ toggle', false)
	        awful.spawn.easy_async_with_shell(
		        [[bash -c "amixer -D pulse sget Master"]],
		        function(stdout)
                    local state  = string.match(stdout, '%[(o[nf]*)%]')
                    state = state:lower()
		        	local muted = state == "off"
                    if muted == true then
		        	    awesome.emit_signal('widget::volume_mute')
                    else
		        	    awesome.emit_signal('widget::volume')
		        	    awesome.emit_signal('module::volume_osd:show', true)
                    end
		        end
            )
		end,
		{description = 'toggle mute', group = 'hotkeys'}
	),

	awful.key(
		{},
		'XF86AudioNext',
		function()
			awful.spawn('mpc next', false)
		end,
		{description = 'next music', group = 'hotkeys'}
	),

	awful.key(
		{},
		'XF86AudioPrev',
		function()
			awful.spawn('mpc prev', false)
		end,
		{description = 'previous music', group = 'hotkeys'}
	),

	awful.key(
		{},
		'XF86AudioPlay',
		function()
			awful.spawn('mpc toggle', false)
		end,
		{description = 'play/pause music', group = 'hotkeys'}

	),

	awful.key(
		{},
		'XF86AudioMicMute',
		function()
			awful.spawn('amixer set Capture toggle', false)
		end,
		{description = 'mute microphone', group = 'hotkeys'}
	),

	awful.key(
		{},
		'XF86PowerOff',
		function()
			awesome.emit_signal('module::exit_screen:show')
		end,
		{description = 'toggle exit screen', group = 'hotkeys'}
	),

	awful.key(
		{},
		'XF86Display',
		function()
			awful.spawn.single_instance('arandr', false)
		end,
		{description = 'arandr', group = 'hotkeys'}
	)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	-- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
	local descr_view, descr_toggle, descr_move, descr_toggle_focus
	if i == 1 or i == 9 then
		descr_view = {description = 'view tag #', group = 'tag'}
		descr_toggle = {description = 'toggle tag #', group = 'tag'}
		descr_move = {description = 'move focused client to tag #', group = 'tag'}
		descr_toggle_focus = {description = 'toggle focused client on tag #', group = 'tag'}
	end
	global_keys =
		awful.util.table.join(
		global_keys,
		-- View tag only.
		awful.key(
			{modkey},
			'#' .. i + 9,
			function()
				local focused = awful.screen.focused()
				local tag = focused.tags[i]
				if tag then
					tag:view_only()
				end
			end,
			descr_view
		),
		-- Toggle tag display.
		awful.key(
			{modkey, 'Control'},
			'#' .. i + 9,
			function()
				local focused = awful.screen.focused()
				local tag = focused.tags[i]
				if tag then
					awful.tag.viewtoggle(tag)
				end
			end,
			descr_toggle
		),
		-- Move client to tag.
		awful.key(
			{modkey, 'Shift'},
			'#' .. i + 9,
			function()
				if client.focus then
					local tag = client.focus.screen.tags[i]
					if tag then
						client.focus:move_to_tag(tag)
					end
				end
			end,
			descr_move
		)
	)
end

return global_keys


local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local naughty = require('naughty')
local beautiful = require('beautiful')
local filesystem = gears.filesystem
local config_dir = filesystem.get_configuration_dir()
local dpi = beautiful.xresources.apply_dpi
local apps = require('configuration.apps')
local widget_icon_dir = config_dir .. 'configuration/user-profile/'
local config = require('configuration.config')

require('module.dynamic-wallpaper')
require('module.auto-start')
require('module.exit-screen')

-- Add paths to package.cpath
package.cpath = package.cpath .. ';' .. config_dir .. '/library/?.so;' .. '/usr/lib/lua-pam/?.so;'

-- Configuration table
local locker_config = {
	-- Clock mode
	military_clock = config.module.lockscreen.military_clock or false,
	-- Fallback password
	fallback_password = function()
		return config.module.lockscreen.fallback_password or 'toor'
	end,
	-- Capture a picture using webcam
	capture_intruder = config.module.lockscreen.capture_intruder or false,
	-- Save location, auto creates
	face_capture_dir = config.module.lockscreen.face_capture_dir or '$HOME/Pictures/Intruders/',
	-- Blur background
	blur_background = config.module.lockscreen.blur_background or false,
	-- Background directory
	bg_dir = config.module.lockscreen.bg_dir or (config_dir .. 'theme/wallpapers/'),
	-- Default background
	-- bg_image = config.module.lockscreen.bg_image or 'morning-wallpaper.jpg',
	-- /tmp directory
	tmp_wall_dir = config.module.lockscreen.tmp_wall_dir or '/tmp/awesomewm/' .. os.getenv('USER') .. '/'
}

-- Useful variables (DO NOT TOUCH THESE)
local input_password = nil
local lock_again = nil
local type_again = true
local capture_now = locker_config.capture_intruder
local locked_tag = nil
local client_focused = nil

local uname_text = wibox.widget {
	id = 'uname_text',
	markup = '$USER',
	font = 'Hack Nerd Bold 14',
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local caps_text = wibox.widget {
	id = 'uname_text',
	markup = 'Caps Lock is on',
	font = 'Hack Nerd Italic 12',
	align = 'center',
	valign = 'center',
	opacity = 0.0,
	widget = wibox.widget.textbox
}

local profile_imagebox = wibox.widget {
	id = 'user_icon',
	image = widget_icon_dir .. 'default.svg',
	resize = true,
	forced_height = dpi(130),
	forced_width = dpi(130),
	clip_shape = gears.shape.circle,
	widget = wibox.widget.imagebox
}

local clock_format = '<span font="Hack Nerd Bold 52">%H:%M</span>'
if not locker_config.military_clock then
	clock_format = '<span font="Hack Nerd Bold 52">%I:%M %p</span>'
end

-- Create clock widget
local time = wibox.widget.textclock(clock_format, 1)

local wanted_text = wibox.widget {
	markup = 'INTRUDER ALERT!',
	font   = 'Hack Nerd Bold 14',
	align  = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local msg_table = {
	'This incident will be reported.',
	'We are watching you.',
	'We know where you live.',
	'RUN!',
	'Yamete, Oniichan~ uwu',
	'This will self-destruct in 5 seconds!',
	'Image successfully sent!',
	'You\'re doomed!',
	'Authentication failed!',
	'I am watching you.',
	'I know where you live.',
	'RUN!',
	'Your parents must be proud of you.'
}

local wanted_msg = wibox.widget {
	markup = 'This incident will be reported!',
	font   = 'Hack Nerd Regular 12',
	align  = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local wanted_image = wibox.widget {
	image  = widget_icon_dir .. 'default.svg',
	resize = true,
	forced_height = dpi(120),
	clip_shape = gears.shape.rounded_rect,
	widget = wibox.widget.imagebox
}

local date_value = function()
	local ordinal = nil
	local date = os.date('%d')
	local day = os.date('%A')
	local month = os.date('%B')

	local first_digit = string.sub(date, 0, 1)
	local last_digit = string.sub(date, -1)
	if first_digit == '0' then
	  date = last_digit
	end

	if last_digit == '1' and date ~= '11' then
	  ordinal = 'st'
	elseif last_digit == '2' and date ~= '12' then
	  ordinal = 'nd'
	elseif last_digit == '3' and date ~= '13' then
	  ordinal = 'rd'
	else
	  ordinal = 'th'
	end

	return date .. ordinal .. ' of ' .. month .. ', ' .. day
end

local date_today = wibox.widget {
	markup = date_value(),
	font = 'Hack Nerd Bold 20',
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local update_date_text = function()
    date_today.markup = date_value()
end

local circle_container = wibox.widget {
	bg = beautiful.transparent,
	forced_width = dpi(140),
	forced_height = dpi(140),
	shape = gears.shape.circle,
	widget = wibox.container.background
}

local locker_arc = wibox.widget {
	bg = beautiful.transparent,
	forced_width = dpi(140),
	forced_height = dpi(140),
	shape = function(cr, width, height)
		gears.shape.arc(cr, width, height, dpi(5), 0, (math.pi / 2), false, false)
	end,
	widget = wibox.container.background
}

local rotate_container = wibox.container.rotate()
local locker_widget = wibox.widget {
	{
		locker_arc,
		widget = rotate_container
	},
	layout = wibox.layout.fixed.vertical
}

-- Rotation direction table
local rotation_direction = {'north', 'west', 'south', 'east'}

-- Red, Green, Yellow, Blue
local red = beautiful.system_red_light
local green = beautiful.system_green_light
local yellow = beautiful.system_yellow_light
local blue = beautiful.system_blue_light

-- Color table
local arc_color = {red, green, yellow, blue}

-- Processes
local locker = function(s)

	local lockscreen = wibox {
		screen = s,
		visible = false,
		ontop = true,
		type = 'splash',
		width = s.geometry.width,
		height = s.geometry.height,
		bg = beautiful.fg_normal,
		fg = beautiful.background_light
	}

	-- Update username textbox
	awful.spawn.easy_async_with_shell(
		[[
		fullname="$(getent passwd `whoami` | cut -d ':' -f 5 | cut -d ',' -f 1 | tr -d "\n")"
		if [ -z "$fullname" ];
		then
			printf "$(whoami)@$(uname -n)"
		else
			printf "$fullname"
		fi
		]],
		function(stdout)
			stdout = stdout:gsub('%\n','')
			uname_text:set_markup(stdout)
		end
	)

	local update_profile_pic = function()
		awful.spawn.easy_async_with_shell(
			apps.utils.update_profile,
			function(stdout)
				stdout = stdout:gsub('%\n','')
				if not stdout:match('default') then
					profile_imagebox:set_image(stdout)
				else
					profile_imagebox:set_image(widget_icon_dir .. 'default.svg')
				end
			end
		)
	end

	-- Update image
	gears.timer.start_new(
		2,
		function()
			update_profile_pic()
		end
	)

	local wanted_poster = awful.popup {
		widget = {
			{
				{
					wanted_text,
					{
						nil,
						wanted_image,
						nil,
						expand = 'none',
						layout = wibox.layout.align.horizontal
					},
					wanted_msg,
					spacing = dpi(5),
					layout = wibox.layout.fixed.vertical
				},
				margins = dpi(20),
				widget = wibox.container.margin
			},
			bg = beautiful.background,
			shape = gears.shape.rounded_rect,
			widget = wibox.container.background
		},
		bg = beautiful.transparent,
		type = 'utility',
		ontop = true,
		shape = gears.shape.rectangle,
		maximum_width = dpi(250),
		maximum_height = dpi(250),
		hide_on_right_click = false,
		preferred_anchors = {'middle'},
		visible = false
	}

	-- Place wanted poster at the bottom of primary screen
	awful.placement.top(
		wanted_poster,
		{
			margins =  {
				top = dpi(10)
			}
		}
	)

	-- Check Capslock state
	local check_caps = function()
		awful.spawn.easy_async_with_shell(
			'xset q | grep Caps | cut -d: -f3 | cut -d0 -f1 | tr -d \' \'',
			function(stdout)
				if stdout:match('on') then
					caps_text.opacity = 1.0
				else
					caps_text.opacity = 0.0
				end
				caps_text:emit_signal('widget::redraw_needed')
			end
		)
	end

	-- Rotate the color arc on random direction
	local locker_arc_rotate = function()

		local direction = rotation_direction[math.random(#rotation_direction)]
		local color = arc_color[math.random(#arc_color)]

		rotate_container.direction = direction
		locker_arc.bg = color

		rotate_container:emit_signal('widget::redraw_needed')
		locker_arc:emit_signal('widget::redraw_needed')
		locker_widget:emit_signal('widget::redraw_needed')
	end

	-- Check webcam
	local check_webcam = function()
		awful.spawn.easy_async_with_shell(
			'ls -l /dev/video* | grep ' .. config.module.lockscreen.camera_device,
			function(stdout)
				if not locker_config.capture_intruder then
					capture_now = false
					return
				end

				if not stdout:match(config.module.lockscreen.camera_device) then
					capture_now = false
				else
					capture_now = true
				end
			end
		)
	end

	check_webcam()

	-- Snap an image of the intruder
	local intruder_capture = function()
		local capture_image = [[
		save_dir="]] .. locker_config.face_capture_dir .. [["
		date="$(date +%Y%m%d_%H%M%S)"
		file_loc="${save_dir}SUSPECT-${date}.png"

		if [ ! -d "$save_dir" ]; then
			mkdir -p "$save_dir";
		fi

		ffmpeg -f video4linux2 -s 800x600 -i ]] .. config.module.lockscreen.camera_device .. [[ -ss 0:0:2 -frames 1 "${file_loc}"

		canberra-gtk-play -i camera-shutter &
		echo "${file_loc}"
		]]

		-- Capture the filthy intruder face
		awful.spawn.easy_async_with_shell(
			capture_image,
			function(stdout)
				circle_container.bg = beautiful.transparent

				-- Humiliate the intruder by showing his/her hideous face
				wanted_image:set_image(stdout:gsub('%\n',''))
				wanted_msg:set_markup(msg_table[math.random(#msg_table)])
				wanted_poster.visible= true

				awful.placement.top(
					wanted_poster,
					{
						margins = {
							top = dpi(10)
						}
					}
				)

				wanted_image:emit_signal('widget::redraw_needed')
				type_again = true
			end
		)
	end

	-- Login failed
	local stoprightthereyoucriminalscum = function()
		circle_container.bg = red
		if capture_now then
			intruder_capture()
		else
			gears.timer.start_new(
				1,
				function()
					circle_container.bg = beautiful.transparent
					type_again = true
				end
			)
		end
	end

	-- Login successful
	local generalkenobi_ohhellothere = function()
		circle_container.bg = green

		-- Add a little delay before unlocking completely
		gears.timer.start_new(
			1,
			function()
				if capture_now then
					-- Hide wanted poster
					wanted_poster.visible = false
				end

				-- Hide all the lockscreen on all screen
				for s in screen do
					if s.index == 1 then
						s.lockscreen.visible = false
					else
						s.lockscreen_extended.visible = false
					end
				end

				circle_container.bg = beautiful.transparent
				lock_again = true
				type_again = true

                awesome.emit_signal('module::unlocked')

                -- Do not resume notifications if dont_disturb_state mode is on
                -- Or if the info_center is visible
                local focused = awful.screen.focused()
                if not (_G.dont_disturb_state or (focused.info_center and focused.info_center.visible)) then
                    -- naughty.destroy_all_notifications(nil, 1)
                    naughty.suspended = false
                end

				-- Select old tag
				-- And restore minimized focused client if there's any
				if locked_tag then
					locked_tag.selected = true
					locked_tag = nil
				end

				if client_focused then
                    client_focused.minimized = false
					c:emit_signal('request::activate')
					c:raise()
				end
			end
		)
	end
	-- A backdoor.
	-- Sometimes I'm too lazy to type so I decided to create this.
	-- Sometimes my genius is... it's almost frightening.
	local back_door = function()
		generalkenobi_ohhellothere()
	end

	-- Check module if valid
	local module_check = function(name)
		if package.loaded[name] then
			return true
		else
			for _, searcher in ipairs(package.searchers or package.loaders) do
				local loader = searcher(name)
				if type(loader) == 'function' then
					package.preload[name] = loader
					return true
				end
			end
			return false
		end
	end

	-- Password/key grabber
	local password_grabber = awful.keygrabber {
		auto_start          = true,
		stop_event          = 'release',
		mask_event_callback = true,
		keybindings = {
			awful.key {
				modifiers = {'Control'},
				key       = 'u',
				on_press  = function()
					input_password = nil
				end
			},
			awful.key {
				modifiers = {'Mod1', 'Mod4', 'Shift', 'Control'},
				key       = 'Return',
				on_press  = function(self)
					if not type_again then
						return
					end
					self:stop()

					-- Call backdoor
					back_door()
				end
			}
		},
		keypressed_callback = function(self, mod, key, command)
			if not type_again then
				return
			end

			-- Clear input string
			if key == 'Escape' then
				-- Clear input threshold
				input_password = nil
				return
			end

			-- Accept only the single charactered key
			-- Ignore 'Shift', 'Control', 'Return', 'F1', 'F2', etc., etc.
			if #key == 1 then
				locker_arc_rotate()

				if input_password == nil then
					input_password = key
					return
				end
				input_password = input_password .. key
			end

		end,
		keyreleased_callback = function(self, mod, key, command)
			locker_arc.bg = beautiful.transparent
			locker_arc:emit_signal('widget::redraw_needed')

			if key == 'Caps_Lock' then
				check_caps()
				return
			end

			if not type_again then
				return
			end

			-- Validation
			if key == 'Return' then
				-- Validate password
				local authenticated = false
				if input_password ~= nil then
					-- If lua-pam library is 'okay'
					if module_check('liblua_pam') then
						local pam = require('liblua_pam')
						authenticated = pam:auth_current_user(input_password)
					else
						-- Library doesn't exist or returns an error due to some reasons (read the manual)
						-- Use fallback password data
						authenticated = input_password == locker_config.fallback_password()
					end
				end

				if authenticated then
					-- Come in!
					self:stop()
					generalkenobi_ohhellothere()
				else
					-- F*ck off, you [REDACTED]!
					stoprightthereyoucriminalscum()
				end

				-- Allow typing again and empty password container
				type_again = false
				input_password = nil
			end
		end
	}

	lockscreen : setup {
		layout = wibox.layout.align.vertical,
		expand = 'none',
		nil,
		{
			layout = wibox.layout.align.horizontal,
			expand = 'none',
			nil,
			{
				layout = wibox.layout.fixed.vertical,
				expand = 'none',
				spacing = dpi(20),
				{
					{
						layout = wibox.layout.align.horizontal,
						expand = 'none',
						nil,
						time,
						nil
					},
					{
						layout = wibox.layout.align.horizontal,
						expand = 'none',
						nil,
						date_today,
						nil
					},
					expand = 'none',
					layout = wibox.layout.fixed.vertical
				},
				{
					layout = wibox.layout.fixed.vertical,
					{
						circle_container,
						locker_widget,
						{
							layout = wibox.layout.align.vertical,
							expand = 'none',
							nil,
							{
								layout = wibox.layout.align.horizontal,
								expand = 'none',
								nil,
								profile_imagebox,
								nil
							},
							nil,
						},
						layout = wibox.layout.stack
					},
					uname_text,
					caps_text
				},
			},
			nil
		},
		nil
	}

    -- Exit screen sends this signal when sleep is requested
    awesome.connect_signal(
    	'module::sleep_resumed',
    	function()
            -- Force update date widget
            update_date_text()
            date_today:emit_signal('widget::redraw_needed')

            awesome.emit_signal('module::spawn_apps')
            awesome.emit_signal('module::change_wallpaper')
            awesome.emit_signal('module::change_background_wallpaper')
    	end
    )

	local show_lockscreen = function()
		-- Why is there a lock_again variable?
		-- It prevents the user to spam locking while in a process of authentication
		-- Prevents a potential bug/problem
		if lock_again == true or lock_again == nil then
			-- Force update clock widget
			time:emit_signal('widget::redraw_needed')

			-- Check capslock status
			check_caps()

			-- Check webcam status
			check_webcam()

			-- Show all the lockscreen on each screen
			for s in screen do
				if s.index == 1 then
					s.lockscreen.visible = true
				else
					s.lockscreen_extended.visible = true
				end
			end

			-- Start keygrabbing, but with a little delay to
			-- give some extra time for the free_keygrab function
			gears.timer.start_new(
				0.5,
				function()
					-- Start key grabbing for password
					password_grabber:start()
				end
			)

			-- Dont lock again
			lock_again = false

            -- Do not suspend notifications if dont_disturb_state mode is on
            -- Or if the info_center is visible
            local focused = awful.screen.focused()
            if not (_G.dont_disturb_state or (focused.info_center and focused.info_center.visible)) then
                -- naughty.destroy_all_notifications(nil, 1)
                naughty.suspended = true
            end

			-- send signal to exit screen (needed during suspend)
			awesome.emit_signal('module::locked')
		end
	end

	local free_keygrab = function()
		-- Kill rofi instance.
		awful.spawn.with_shell('kill -9 $(pgrep rofi)')

		-- Check if there's a keygrabbing instance.
		-- If yes, stop it.
		local keygrabbing_instance = awful.keygrabber.current_instance
		if keygrabbing_instance then
			keygrabbing_instance:stop()
		end

		-- Unselect all tags and minimize the focused client
		-- These will fix the problem with virtualbox or
		-- any other program that has keygrabbing enabled
		if client.focus then
            client_focused = client.focus
			client.focus.minimized = true
		end
		for _, t in ipairs(mouse.screen.selected_tags) do
			locked_tag = t
			t.selected = false
		end
	end

	awesome.connect_signal(
		'module::lockscreen_show',
		function()
			if lock_again == true or lock_again == nil then
				free_keygrab()
				show_lockscreen()
			end
		end
	)
	return lockscreen
end

-- This lockscreen is for the extra/multi monitor
local locker_ext = function(s)
	local extended_lockscreen = wibox {
		screen = s,
		visible = false,
		ontop = true,
		ontype = 'true',
		x = s.geometry.x,
		y = s.geometry.y,
		width = s.geometry.width,
		height = s.geometry.height,
		bg = beautiful.fg_normal,
		fg = beautiful.background_light
	}
	return extended_lockscreen
end

-- Create lockscreen for each screen
local create_lock_screens = function(s)
	if s.index == 1 then
		s.lockscreen = locker(s)
	else
		s.lockscreen_extended = locker_ext(s)
	end
end

-- Don't show notification popups if the screen is locked
local check_lockscreen_visibility = function()
	focused = awful.screen.focused()
	if focused.lockscreen and focused.lockscreen.visible then
		return true
	end
	if focused.lockscreen_extended and focused.lockscreen_extended.visible then
		return true
	end
	return false
end

-- Notifications signal
-- Check for added since we are doing suspended instead of destroy_all_notifications
naughty.connect_signal(
	'added',
	function(_)
		if check_lockscreen_visibility() then
            -- Do not suspend notifications if dont_disturb_state mode is on
            -- Or if the info_center is visible
            local focused = awful.screen.focused()
            if not (_G.dont_disturb_state or (focused.info_center and focused.info_center.visible)) then
                -- naughty.destroy_all_notifications(nil, 1)
                naughty.suspended = true
            end
		end
	end
)

-- Filter background image
local filter_bg_image = function(wall_name, index, ap, width, height)
	-- Checks if the blur has to be blurred
	local blur_filter_param = ''
	if locker_config.blur_background then
		blur_filter_param = '-filter Gaussian -blur 0x10'
	end

	-- Create imagemagick command
	local magic = [[
	sh -c "
	if [ ! -d ]] .. locker_config.tmp_wall_dir ..[[ ];
	then
		mkdir -p ]] .. locker_config.tmp_wall_dir .. [[;
	fi
	convert -quality 100 -brightness-contrast -20x0 ]] .. ' '  .. blur_filter_param .. ' '.. locker_config.bg_dir .. wall_name ..
	[[ -gravity center -crop ]] .. ap .. [[:1 +repage -resize ]] .. width .. 'x' .. height ..
	[[! ]] .. locker_config.tmp_wall_dir .. index .. wall_name .. [[
	"]]
	return magic
end

-- Apply lockscreen background image
local apply_ls_bg_image = function(wall_name)
	-- Iterate through all the screens and create a lockscreen for each of it
	for s in screen do
		local index = s.index .. '-'

		-- Get screen geometry
		local screen_width = s.geometry.width
		local screen_height = s.geometry.height

		-- Get the right resolution/aspect ratio that will be use as the background
		local aspect_ratio = screen_width / screen_height
		aspect_ratio = math.floor(aspect_ratio * 100) / 100

		-- Create image filter command
		local cmd = nil
		cmd = filter_bg_image(wall_name, index, aspect_ratio, screen_width, screen_height)

		-- Asign lockscreen to each screen
		if s.index == 1 then
			-- Primary screen
			awful.spawn.easy_async_with_shell(
				cmd,
				function()
					s.lockscreen.bgimage = locker_config.tmp_wall_dir .. index .. wall_name
				end
			)
		else
			-- Multihead screen/s
			awful.spawn.easy_async_with_shell(
				cmd,
				function()
					s.lockscreen_extended.bgimage = locker_config.tmp_wall_dir .. index .. wall_name
				end
			)
		end
	end
end

awesome.connect_signal(
	'module::change_background_wallpaper',
	function()
		-- Update lockscreen wallpaper
		apply_ls_bg_image(get_wallpaper_name())
	end
)

-- Create a lockscreen and its background for each screen on start-up
screen.connect_signal(
	'request::desktop_decoration',
	function(s)
		create_lock_screens(s)
		apply_ls_bg_image(get_wallpaper_name())
	end
)

-- Regenerate lockscreens and its background if a screen was removed to avoid errors
screen.connect_signal(
	'removed',
	function(s)
		create_lock_screens(s)
		apply_ls_bg_image(get_wallpaper_name())
	end
)

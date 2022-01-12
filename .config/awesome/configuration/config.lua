return {
	widget = {
		email  = {
			-- Email address
			address = '',
			-- App password
			app_password = '',
			-- Imap server
			imap_server = 'imap.gmail.com',
			-- Port
			port = '993'
		},

		weather = {
			-- API Key
			key = '',
			-- City ID
			city_id = '',
			-- Units
			units = 'metric',
			-- Update in N seconds
			update_interval = 1200
		},

		network = {
			-- Wired interface
			wired_interface = 'enp0s31f6',
			-- Wireless interface
			wireless_interface = 'wlp2s0'
		},

		clock = {
			-- Clock widget format
			military_mode = false
		},

		screen_recorder = {
			-- Default record dimension
			resolution = '1366x768',
			-- X,Y coordinate
			offset = '0,0',
			-- Enable audio by default
			audio = false,
			-- Recordings directory
			save_directory = '$(xdg-user-dir VIDEOS)/Recordings/',
			-- Mic level
			mic_level = '20',
			-- FPS
			fps = '30'
		}
	},

	module = {
		auto_start = {
			-- Will create notification if true
			debug_mode = true
		},

		dynamic_wallpaper = {
			-- Will look for wallpapers here
			wall_dir = 'theme/wallpapers/',
			-- Image formats
			valid_picture_formats = {'jpg', 'png', 'jpeg'},
			-- Leave this table empty for full auto scheduling
			wallpaper_schedule = {
				['01:30:00'] = 'night02-wallpaper.jpg',
				['04:00:00'] = 'night03-wallpaper.jpg',
				['06:22:00'] = 'morning01-wallpaper.jpg',
				['07:45:00'] = 'morning02-wallpaper.jpeg',
				['09:15:00'] = 'morning03-wallpaper.jpeg',
				['11:00:00'] = 'morning04-wallpaper.jpeg',
				['12:30:00'] = 'noon01-wallpaper.jpg',
				['14:30:00'] = 'noon02-wallpaper.jpeg',
				['16:30:00'] = 'noon03-wallpaper.jpeg',
				['18:30:00'] = 'evening01-wallpaper.jpg',
				['20:30:00'] = 'evening02-wallpaper.jpg',
				['23:00:00'] = 'night01-wallpaper.jpg'
				-- Example of just using auto-scheduling with keywords
				--[[
					'midnight',
					'morning',
					'noon',
					'afternoon',
					'evening',
					'night'
				--]]
			},
			-- Stretch background image across all screens(monitor)
			stretch = false
		},

		lockscreen = {
			-- Clock format
			military_clock = true,
			-- Default password if there's no PAM integration
			fallback_password = 'toor',
			-- Capture intruder using webcam
			capture_intruder = true,
			-- Intruder image save location (Will create directory if it doesn't exist)
			face_capture_dir = '$(xdg-user-dir PICTURES)/Intruders/',
			-- Background directory - Defaults to 'awesome/config/theme/wallpapers/' if null
			bg_dir = nil,
			-- Will look for this image file under 'bg_dir'
			bg_image = 'locksreen-bg.jpg',
			-- Blur lockscreen background
			blur_background = false,
			-- Blurred/filtered background image path (No reason to change this)
			tmp_wall_dir = '/tmp/awesomewm/' .. os.getenv('USER') .. '/'
		}
	}
}

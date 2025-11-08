local filesystem = require('gears.filesystem')
local config_dir = filesystem.get_configuration_dir()
local utils_dir = config_dir .. 'utilities/'

return {
    display = {
        -- DPI setting for all displays
        dpi = 192,

        -- Primary display (laptop)
        primary = {
            name = 'eDP-1',
            mode = '3840x2400',
            position = '0x0',
            -- Additional settings
            rate = nil, -- Optional: refresh rate (e.g., '60')
        },

        -- External display
        external = {
            name = 'DP-4',
            mode = '3440x1440',
            position = '3840x0', -- Position relative to primary
            -- Scaling: scale external to match primary height
            -- This makes cursor movement smooth between displays
            scale_from = '3840x2400', -- Scale to match primary dimensions
            rate = nil,               -- Optional: refresh rate
        },
    },

    keyboard = {
        script = utils_dir .. 'kbd-bkl',
        file = '/sys/class/leds/dell::kbd_backlight/brightness'
        -- file = '/sys/class/leds/smc::kbd_backlight/brightness'
        -- file = '/sys/class/leds/tpacpi::kbd_backlight/brightness'
    },

    widget = {
        email           = {
            -- Email address
            address = '',
            -- App password
            app_password = '',
            -- Imap server
            imap_server = 'imap.gmail.com',
            -- Port
            port = '993'
        },

        weather         = {
            -- API Key
            key = '25bc90a1196e6f153eece0bc0b0fc9eb',
            -- City ID
            -- SJ
            city_id = '5392171',
            -- -- Mys
            -- city_id = '1262321',
            -- Units
            units = 'metric',
            -- Update in N seconds
            update_interval = 1200
        },

        clock           = {
            -- Clock widget format
            military_mode = false
        },

        screen_recorder = {
            -- Which display to record from: "primary" or "external"
            display_target = 'external',
            -- Resolution and offset are automatically detected from display config
            -- based on the display_target setting above
            -- Enable audio by default
            audio = false,
            -- Recordings directory
            save_directory = '$HOME/Videos/Recordings/',
            -- Mic level
            mic_level = '100',
            -- FPS
            fps = '60'
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
            valid_picture_formats = { 'jpg', 'png', 'jpeg' },
            -- Leave this table empty for full auto scheduling
            wallpaper_schedule = {
                ['00:00:00'] = 'am_12.jpg',
                ['05:00:00'] = 'am_05.jpg',
                ['05:30:00'] = 'am_05_30.jpg',
                ['06:00:00'] = 'am_06.jpg',
                ['06:30:00'] = 'am_06_30.jpg',
                ['07:00:00'] = 'am_07.jpg',
                ['07:30:00'] = 'am_07_30.jpg',
                ['08:00:00'] = 'am_08.jpg',
                ['08:30:00'] = 'am_08_30.jpg',
                ['09:00:00'] = 'am_09.jpg',
                ['09:30:00'] = 'am_09_30.jpg',
                ['10:00:00'] = 'am_10.jpg',
                ['10:30:00'] = 'am_10_30.jpg',
                ['11:00:00'] = 'am_11.jpg',
                ['11:30:00'] = 'am_11_30.jpg',
                ['12:00:00'] = 'pm_12.jpg',
                ['12:30:00'] = 'pm_12_30.jpg',
                ['13:00:00'] = 'pm_01.jpg',
                ['14:00:00'] = 'pm_02.jpg',
                ['15:00:00'] = 'pm_03.jpg',
                ['17:00:00'] = 'pm_05.jpg',
                ['18:00:00'] = 'pm_06.jpg',
                ['18:30:00'] = 'pm_06_30.jpg',
                ['19:00:00'] = 'pm_07.jpg',
                ['19:30:00'] = 'pm_07_30.jpg',
                ['20:00:00'] = 'pm_08.jpg',
                ['20:30:00'] = 'pm_08_30.jpg',
                ['21:00:00'] = 'pm_09.jpg',
                ['21:30:00'] = 'pm_09_30.jpg',
                ['22:00:00'] = 'pm_10.jpg'
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
            capture_intruder = false,
            -- Camera path (Some systemts will have more than one built-in
            -- camera, pick the right one with this command
            -- $ v4l2-ctl --list-devices
            camera_device = '/dev/video8',
            capture_script = utils_dir .. 'capture',
            -- Intruder image save location (Will create directory if it doesn't exist)
            face_capture_dir = '$HOME/Pictures/Intruders/',
            -- Background directory - Defaults to 'awesome/config/theme/wallpapers/' if null
            bg_dir = nil,
            -- Will look for this image file under 'bg_dir'
            bg_image = 'locksreen-bg.jpg',
            -- Blur lockscreen background
            blur_background = false,
            -- Blurred/filtered background image path (No reason to change this)
            tmp_wall_dir = '/tmp/awesomewm/' .. (os.getenv('USER') or 'unknown') .. '/'
        }
    }
}

local filesystem = require('gears.filesystem')
local config_dir = filesystem.get_configuration_dir()
local utils_dir = config_dir .. 'utilities/'

return {
    keyboard = {
        script = utils_dir .. 'kbd-bkl',
        file = '/sys/class/leds/dell::kbd_backlight/brightness'
        -- file = '/sys/class/leds/smc::kbd_backlight/brightness'
        -- file = '/sys/class/leds/tpacpi::kbd_backlight/brightness'
    },

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
            key = '25bc90a1196e6f153eece0bc0b0fc9eb',
            -- City ID
            city_id = '5392171',
            -- Units
            units = 'metric',
            -- Update in N seconds
            update_interval = 1200
        },

        network = {
            -- Wired interface
            wired_interface = 'enp0s31f6',
            -- Wireless interface
            wireless_interface = 'wlan0'
        },

        clock = {
            -- Clock widget format
            military_mode = false
        },

        screen_recorder = {
            -- Default record dimension
            resolution = '2560x1440',
            -- X,Y coordinate
            offset = '0,0',
            -- Enable audio by default
            audio = false,
            -- Recordings directory
            save_directory = '$HOME/Videos/Recordings/',
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
            capture_intruder = true,
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
            tmp_wall_dir = '/tmp/awesomewm/' .. os.getenv('USER') .. '/'
        }
    }
}

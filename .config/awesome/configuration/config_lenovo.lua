local filesystem = require('gears.filesystem')
local config_dir = filesystem.get_configuration_dir()
local utils_dir = config_dir .. 'utilities/'

return {
    -- Preserve laptop controls while selecting the managed Lenovo variant.
    machine = 'laptop',
    profile = 'lenovo',
    display = {
        dpi = 96,
        cursor_size = 32,
        browser_scale = 1,
        primary = {
            name = 'eDP-1',
            mode = '1920x1200',
            position = '0x0',
            rate = nil,
        },
        external = {
            name = 'DP-1',
            mode = '3440x1440',
            position = '1920x0',
            scale_from = '3440x1440',
            rate = nil,
        },
    },
    keyboard = {
        script = utils_dir .. 'input/kbd-bkl',
        file = '/sys/class/leds/tpacpi::kbd_backlight/brightness',
    },
    widget = {
        audio = {
            primary_device_pattern = 'alsa_card.pci-0000_00_1f.3-platform-sof_sdw',
            external_device_pattern = 'alsa_card.usb-Dell_DELL_P3424WEB_USB_*-00',
        },
        email = {
            address = '',
            app_password = '',
            imap_server = 'imap.gmail.com',
            port = '993',
        },
        weather = {
            providers = { 'open-meteo', 'wttr' },
            locations = {
                {
                    name = 'San Jose', country = 'US',
                    latitude = 37.3382, longitude = -121.8863,
                    timezone = 'America/Los_Angeles', wttr_query = 'San Jose',
                    openweather_city_id = '5392171',
                },
                {
                    name = 'Mysore', country = 'IN',
                    latitude = 12.2958, longitude = 76.6394,
                    timezone = 'Asia/Kolkata', wttr_query = 'Mysore',
                    openweather_city_id = '1262321',
                },
            },
            open_weather = {
                key = '',
                city_ids = { '5392171', '1262321' },
            },
            units = 'metric',
            update_interval = 1200,
        },
        clock = { military_mode = false },
        stocks = {
            symbols = { 'NVDA', 'TQQQ', 'TECL' },
            update_interval = 300,
        },
        calendar_events = {
            script = config_dir .. 'utilities/network/outlook-calendar',
            window_days = 2,
            max_items = 0,
            show_cancelled = false,
        },
        calendar_holidays = {
            script = config_dir .. 'utilities/network/calendar-holidays',
        },
        screen_recorder = {
            display_target = 'primary',
            audio = false,
            save_directory = '$HOME/Videos/Recordings/',
            mic_level = '100',
            fps = '60',
        },
        screenshot = { display_target = 'primary' },
    },
    module = {
        auto_start = { debug_mode = true },
        dynamic_wallpaper = {
            wall_dir = 'theme/wallpapers/',
            valid_picture_formats = { 'jpg', 'png', 'jpeg' },
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
                ['22:00:00'] = 'pm_10.jpg',
            },
            stretch = false,
        },
        lockscreen = {
            military_clock = true,
            fallback_password = 'toor',
            capture_intruder = true,
            fingerprint_unlock = false,
            -- Interface 1.0 is RGB; interface 1.2 (and this camera's by-id link) is IR.
            camera_device = '/dev/v4l/by-path/pci-0000:00:14.0-usb-0:4:1.0-video-index0',
            external_camera_device = '/dev/v4l/by-id/usb-*_DELL_Display_4MP_Webcam_*-video-index0',
            capture_script = utils_dir .. 'camera/capture',
            face_capture_dir = '$HOME/Pictures/Intruders/',
            bg_dir = nil,
            bg_image = nil,
            blur_background = false,
            tmp_wall_dir = '/tmp/awesomewm/' .. (os.getenv('USER') or 'unknown') .. '/',
        },
    },
}

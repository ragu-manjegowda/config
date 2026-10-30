local home = assert(os.getenv('HOME'))
local directory = home .. '/.config/awesome/'
package.path = directory .. '?.lua;' .. directory .. '?/init.lua;' .. package.path
package.loaded['gears.filesystem'] = {
    get_configuration_dir = function() return directory end,
    file_readable = function(path)
        return path == '/sys/class/power_supply/BAT0/type' or
            path == '/sys/class/leds/tpacpi::kbd_backlight/brightness'
    end,
    file_executable = function(path) return path == '/usr/bin/powerprofilesctl' end,
}
local config = require('configuration.config_lenovo')
package.loaded['configuration.config'] = config
assert(config.machine == 'laptop' and config.profile == 'lenovo')
assert(config.display.primary.name == 'eDP-1')
assert(config.display.primary.mode == '1920x1200')
assert(config.display.dpi == 96 and config.display.cursor_size == 32)
assert(config.display.browser_scale == 1)
assert(config.display.external.name == 'DP-1')
assert(config.keyboard.file == '/sys/class/leds/tpacpi::kbd_backlight/brightness')
assert(config.widget.audio.primary_device_pattern == 'alsa_card.pci-0000_00_1f.3-platform-sof_sdw')
assert(config.module.lockscreen.camera_device ==
    '/dev/v4l/by-path/pci-0000:00:14.0-usb-0:4:1.0-video-index0')
assert(not config.module.lockscreen.fingerprint_unlock)
assert(config.widget.screen_recorder.display_target == 'primary')
assert(config.widget.screenshot.display_target == 'primary')
for _, provider in ipairs(config.widget.weather.providers) do
    assert(provider ~= 'open-weather' or config.widget.weather.open_weather.key ~= '')
end
for _, name in pairs(config.module.dynamic_wallpaper.wallpaper_schedule) do
    assert(name:match('^[%w_%-]+%.jpg$'), name)
end
local machine = require('library.machine')
assert(machine.battery and machine.power_profile and machine.keyboard_backlight)
local apps = require('configuration.apps')
local resources
for _, command in ipairs(apps.run_on_start_up) do
    if command:find('xrdb %-merge') then resources = command end
end
assert(resources and resources:find('Xft.dpi: 96', 1, true))
assert(resources:find('Xcursor.size: 32', 1, true))
print('Lenovo profile: display, cursor, camera, audio and laptop controls passed')

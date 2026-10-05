local config = require('configuration.config')
local filesystem = require('gears.filesystem')
local M = { kind = config.machine or 'laptop' }
local laptop = M.kind == 'laptop'

-- Do not instantiate unsupported widgets: some battery libraries expect BAT0
-- to exist, and keyboard/power widgets otherwise spawn unusable commands.
M.battery = laptop and filesystem.file_readable('/sys/class/power_supply/BAT0/type') or false
M.power_profile = laptop and filesystem.file_executable('/usr/bin/powerprofilesctl') or false
M.keyboard_backlight = laptop and config.keyboard and config.keyboard.file and
    filesystem.file_readable(config.keyboard.file) or false

return M

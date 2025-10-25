local user_preferences = {}
local config = require('configuration.config')

-- Determine which display to use based on config
local display_target = config.widget.screen_recorder.display_target or 'primary'
local target_display = config.display[display_target] or config.display.primary

-- Get resolution from selected display config (single source of truth)
local display_res = target_display.mode     -- e.g., "3840x2400"
local display_pos = target_display.position -- e.g., "0x0"

-- Screen resolution (from display config)
user_preferences.user_resolution = display_res

-- Offset x,y (from display config)
user_preferences.user_offset = display_pos

-- bool - true or false
user_preferences.user_audio = config.widget.screen_recorder.audio or false

-- String - $HOME
user_preferences.user_save_directory = config.widget.screen_recorder.save_directory or '$HOME/Videos/Recordings/'

-- String
user_preferences.user_mic_lvl = config.widget.screen_recorder.mic_level or '20'

-- String
user_preferences.user_fps = config.widget.screen_recorder.fps or '30'

return user_preferences

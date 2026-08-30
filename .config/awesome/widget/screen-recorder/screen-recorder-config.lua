local user_preferences = {}
local config = require('configuration.config')

-- String - $HOME
user_preferences.user_save_directory = config.widget.screen_recorder.save_directory or '$HOME/Videos/Recordings/'

-- String
user_preferences.user_mic_lvl = config.widget.screen_recorder.mic_level or '20'

-- String
user_preferences.user_fps = config.widget.screen_recorder.fps or '30'

return user_preferences

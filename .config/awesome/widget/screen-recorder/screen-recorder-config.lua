local user_preferences = {}
local config = require('configuration.config')

local function escape_lua_pattern(value)
    return tostring(value):gsub('([^%w])', '%%%1')
end

local function is_output_connected(output_name)
    local handle = io.popen('xrandr --query 2>/dev/null')
    if not handle then
        return false
    end

    local output = handle:read('*a') or ''
    handle:close()

    local pattern = escape_lua_pattern(output_name) .. ' connected'
    return output:match('^' .. pattern) ~= nil or output:match('\n' .. pattern) ~= nil
end

local function parse_size(value)
    local width, height = tostring(value):match('^(%d+)x(%d+)$')
    return tonumber(width), tonumber(height)
end

local function parse_position(value)
    local x, y = tostring(value):match('^(%-?%d+)x(%-?%d+)$')
    return tonumber(x), tonumber(y)
end

local function display_geometry(display)
    local res = display.scale_from or display.mode
    local width, height = parse_size(res)
    local x, y = parse_position(display.position)
    return width, height, x, y
end

local function build_display_config(display)
    local res = display.scale_from or display.mode
    return res, display.position:gsub('x', ',')
end

local function build_both_config(primary, external)
    local pw, ph, px, py = display_geometry(primary)
    local ew, eh, ex, ey = display_geometry(external)

    local min_x = math.min(px, ex)
    local min_y = math.min(py, ey)
    local max_x = math.max(px + pw, ex + ew)
    local max_y = math.max(py + ph, ey + eh)

    return (max_x - min_x) .. 'x' .. (max_y - min_y), min_x .. ',' .. min_y
end

-- Determine which display to use based on config
local display_target = config.widget.screen_recorder.display_target or 'primary'
local external_connected = is_output_connected(config.display.external.name)
local display_res
local display_offset

if display_target == 'external' and external_connected then
    display_res, display_offset = build_display_config(config.display.external)
elseif display_target == 'both' and external_connected then
    display_res, display_offset = build_both_config(config.display.primary, config.display.external)
else
    display_res, display_offset = build_display_config(config.display.primary)
end

-- Screen resolution (from display config)
user_preferences.user_resolution = display_res

-- Offset x,y (from display config, converted to x11grab format)
user_preferences.user_offset = display_offset

-- bool - true or false
user_preferences.user_audio = config.widget.screen_recorder.audio or false

-- String - $HOME
user_preferences.user_save_directory = config.widget.screen_recorder.save_directory or '$HOME/Videos/Recordings/'

-- String
user_preferences.user_mic_lvl = config.widget.screen_recorder.mic_level or '20'

-- String
user_preferences.user_fps = config.widget.screen_recorder.fps or '30'

return user_preferences

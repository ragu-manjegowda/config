local awful = require('awful')
local gears = require('gears')
local user_config = require('widget.screen-recorder.screen-recorder-config')
local recorder_state = require('widget.screen-recorder.screen-recorder-state')
local storage = require('widget.screen-recorder.screen-recorder-storage')

local scripts = {}
local home = assert(os.getenv('HOME'))
local save_directory = user_config.user_save_directory:gsub('^%$HOME', home)
if save_directory:sub(-1) ~= '/' then save_directory = save_directory .. '/' end
local runtime_directory = os.getenv('XDG_RUNTIME_DIR')
if not runtime_directory or runtime_directory == '' then
    runtime_directory = gears.filesystem.get_cache_dir()
end
if runtime_directory:sub(-1) ~= '/' then runtime_directory = runtime_directory .. '/' end
local pid_path = runtime_directory .. 'awesome-screen-recorder.pid'
local active_pid, active_filename, finished_callback
local stopping = false

local function file_exists(path)
    local file = io.open(path, 'rb')
    if not file then return false end
    file:close()
    return true
end

function scripts.owns_arguments(arguments, filename)
    local executable = arguments[1] and arguments[1]:match('([^/]+)$')
    if executable ~= 'ffmpeg' or arguments[2] ~= '-nostdin' or
        arguments[#arguments] ~= filename then return false end
    for _, argument in ipairs(arguments) do
        if argument == '' then return false end
    end
    local has_video_size, has_input, has_x11grab = false, false, false
    for index = 1, #arguments - 1 do
        has_video_size = has_video_size or arguments[index] == '-video_size'
        has_input = has_input or arguments[index] == '-i'
        has_x11grab = has_x11grab or
            (arguments[index] == '-f' and arguments[index + 1] == 'x11grab')
    end
    return has_video_size and has_input and has_x11grab
end

function scripts.parse_command_line(command)
    local arguments, start = {}, 1
    while start <= #command do
        local separator = command:find('\0', start, true)
        if not separator then return nil end
        arguments[#arguments + 1] = command:sub(start, separator - 1)
        start = separator + 1
    end
    return arguments
end

local function owned_process(pid, filename)
    local file = io.open('/proc/' .. tostring(pid) .. '/cmdline', 'rb')
    if not file then return false end
    local command = file:read(4096)
    file:close()
    if not command then return false end
    local arguments = scripts.parse_command_line(command)
    return arguments and scripts.owns_arguments(arguments, filename)
end

local function stop_stale_recording()
    local content = storage.read(pid_path, 4096)
    if not content then return end
    local pid, filename = content:match('^(%d+)\n([^\n]+)$')
    if pid and filename and owned_process(pid, filename) then
        awful.spawn({ 'kill', '-INT', pid })
    end
    storage.remove(pid_path)
end

local function unique_filename()
    gears.filesystem.make_directories(save_directory)
    local base = save_directory .. os.date('%Y-%m-%d_%H-%M-%S')
    for suffix = 0, 999 do
        local candidate = base .. (suffix == 0 and '' or ('-' .. suffix)) .. '.mp4'
        if not file_exists(candidate) then return candidate end
    end
    return nil, 'Could not allocate a recording filename'
end

local function ffmpeg_arguments(audio, geometry, filename)
    local video_size, input = recorder_state.ffmpeg_geometry(geometry)
    local args = {
        'ffmpeg', '-nostdin', '-video_size', video_size,
        '-framerate', tostring(user_config.user_fps),
        '-f', 'x11grab', '-i', input
    }
    if audio then
        args[#args + 1] = '-f'
        args[#args + 1] = 'pulse'
        args[#args + 1] = '-ac'
        args[#args + 1] = '2'
        args[#args + 1] = '-i'
        args[#args + 1] = 'default'
    end
    local output_args = {
        '-c:v', 'libx264', '-crf', '20', '-profile:v', 'baseline',
        '-level', '3.0', '-pix_fmt', 'yuv420p', filename
    }
    for _, argument in ipairs(output_args) do args[#args + 1] = argument end
    return args
end

local function complete_recording(reason, code, last_error)
    local callback, filename = finished_callback, active_filename
    local requested_stop = stopping
    active_pid, active_filename, finished_callback = nil, nil, nil
    stopping = false
    storage.remove(pid_path)
    local success = file_exists(filename) and
        (requested_stop or (reason == 'exit' and code == 0))
    if callback then
        callback(success, filename, success and nil or
            (last_error ~= '' and last_error or ('FFmpeg exited with ' .. tostring(code))))
    end
end

function scripts.start_recording(audio, geometry, callback)
    if active_pid then return nil, 'Recording already active' end
    local filename, filename_error = unique_filename()
    if not filename then return nil, filename_error end
    if audio then
        awful.spawn({
            'wpctl', 'set-volume', '@DEFAULT_AUDIO_SOURCE@',
            tostring(user_config.user_mic_lvl) .. '%'
        })
    end

    local last_error = ''
    local early_exit
    local pid = awful.spawn.with_line_callback(
        ffmpeg_arguments(audio, geometry, filename), {
            stderr = function(line)
                last_error = line:sub(1, 2048)
            end,
            exit = function(reason, code)
                if not active_pid then
                    early_exit = { reason = reason, code = code }
                else
                    complete_recording(reason, code, last_error)
                end
            end
        })
    if type(pid) ~= 'number' then return nil, tostring(pid) end
    if early_exit then
        return nil, last_error ~= '' and last_error or
            ('FFmpeg exited with ' .. tostring(early_exit.code))
    end

    active_pid, active_filename, finished_callback = pid, filename, callback
    local saved, save_error = pcall(
        storage.write, pid_path, tostring(pid) .. '\n' .. filename)
    if not saved then
        awful.spawn({ 'kill', '-INT', tostring(pid) })
        stopping = true
        finished_callback = nil
        return nil, tostring(save_error)
    end
    return pid
end

function scripts.stop_recording()
    if not active_pid or stopping then return false end
    stopping = true
    awful.spawn({ 'kill', '-INT', tostring(active_pid) })
    return true
end

function scripts.is_recording()
    return active_pid ~= nil
end

stop_stale_recording()
return scripts

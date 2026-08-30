local home = assert(os.getenv("HOME"))
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" .. package.path

local test_directory = "/tmp/screen recorder command"
assert(os.execute(string.format("mkdir -p %q", test_directory)))
local ffmpeg_args, ffmpeg_callback, kill_args, exit_immediately
local spawn = setmetatable({
    with_line_callback = function(args, callback)
        ffmpeg_args, ffmpeg_callback = args, callback
        local output = assert(io.open(args[#args], "wb"))
        output:write("recording")
        output:close()
        if exit_immediately then callback.exit("exit", 1) end
        return 4242
    end
}, {
    __call = function(_, args)
        kill_args = args
        return 1
    end
})
package.loaded.awful = { spawn = spawn }
package.loaded.naughty = { action = function() return { connect_signal = function() end } end,
    notification = function() end }
package.loaded.gears = {
    filesystem = {
        get_cache_dir = function() return "/tmp/" end,
        make_directories = function() return true end
    }
}
package.loaded["widget.screen-recorder.screen-recorder-storage"] = {
    read = function() return nil end,
    write = function() end,
    remove = function() end
}
package.loaded["widget.screen-recorder.screen-recorder-config"] = {
    user_audio = false,
    user_save_directory = test_directory .. "/",
    user_mic_lvl = "50",
    user_fps = "60"
}

local scripts = require("widget.screen-recorder.screen-recorder-scripts")
assert(scripts.owns_arguments({
    "/usr/bin/ffmpeg", "-nostdin", "-video_size", "800x600",
    "-f", "x11grab", "-i", ":0.0+0,0", "/tmp/exact.mp4"
}, "/tmp/exact.mp4"), "stale ownership must match exact FFmpeg argv tokens")
assert(not scripts.owns_arguments({
    "/usr/bin/ffmpeg", "-nostdin", "-video_size", "800x600",
    "-f", "x11grab", "-i", ":0.0+0,0", "/tmp/exact.mp4.backup"
}, "/tmp/exact.mp4"), "stale ownership must reject filename substrings")
local parsed = assert(scripts.parse_command_line(
    "ffmpeg\0-nostdin\0\0-f\0x11grab\0-i\0:0.0+0,0\0/tmp/exact.mp4\0"))
assert(parsed[3] == '' and not scripts.owns_arguments(parsed, "/tmp/exact.mp4"),
    "stale ownership must preserve and reject empty argv tokens")
local finished
local pid, err = scripts.start_recording(
    false,
    { x = 101, y = 51, width = 800, height = 602 },
    function(success, filename, message)
        finished = { success = success, filename = filename, message = message }
    end)

assert(pid == 4242 and not err, "recording must return the owned FFmpeg PID")
assert(ffmpeg_args[1] == "ffmpeg" and ffmpeg_args[3] == "-video_size",
    "recording must launch FFmpeg without a shell")
assert(ffmpeg_args[4] == "800x602", "recording must use selected dimensions")
assert(ffmpeg_args[10] == ":0.0+101,51", "recording must use selected offset")
assert(ffmpeg_args[#ffmpeg_args]:match("^/tmp/screen recorder command/"),
    "recording path must remain one argv element")

local second_pid, second_err = scripts.start_recording(false,
    { x = 0, y = 0, width = 800, height = 600 }, function() end)
assert(not second_pid and second_err == "Recording already active",
    "a pending recorder process must block another launch")

assert(scripts.stop_recording(), "stop must signal the owned process")
assert(kill_args[1] == "kill" and kill_args[2] == "-INT" and kill_args[3] == "4242",
    "stop must target only the owned FFmpeg PID")
ffmpeg_callback.exit("signal", 2)
assert(finished and finished.success, "clean FFmpeg exit must report success")

os.remove(finished.filename)
finished = nil
assert(scripts.start_recording(false,
    { x = 0, y = 0, width = 800, height = 600 },
    function(success, filename, message)
        finished = { success = success, filename = filename, message = message }
    end))
ffmpeg_callback.stderr("disk full")
ffmpeg_callback.exit("exit", 1)
assert(finished and not finished.success and finished.message == "disk full",
    "FFmpeg failure must propagate its bounded error")
os.remove(finished.filename)
exit_immediately = true
local early_pid, early_error = scripts.start_recording(false,
    { x = 0, y = 0, width = 800, height = 600 }, function() end)
assert(not early_pid and early_error:match("FFmpeg exited"),
    "immediate FFmpeg exit must not leave active recorder state")
assert(not scripts.is_recording(), "immediate FFmpeg exit must not leave a stale PID")
os.remove(ffmpeg_args[#ffmpeg_args])
exit_immediately = false
assert(os.execute(string.format("rmdir %q", test_directory)))

print("Screen recorder command tests passed")

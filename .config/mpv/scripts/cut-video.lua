---@diagnostic disable: undefined-global
local start_time_formated = nil
local start_time_seconds = nil
local end_time_seconds = nil
local end_time_formated = nil
local utils = require "mp.utils"
local ov = mp.create_osd_overlay("ass-events")

local fn_cut_finish = function(p1, p2)
    if (start_time_seconds == nil or end_time_seconds == nil or
            start_time_formated == nil or end_time_formated == nil) then
        mp.osd_message("time not set")
    else
        local video_args = '-c copy'
        local output_format = mp.get_property("filename"):match("[^.]+$")
        if ((p1 == nil and p2 == nil) or (p1 == '' and p2 == '')) then
        else
            if (p1 == nil or p1 == '') then
            else
                output_format = p1
            end
            if (p2 == nil or p2 == '') then
                video_args = ''
            else
                video_args = p2
            end
        end

        local output_directory, _ = utils.split_path(mp.get_property("path"))

        local output_filename = mp.get_property("filename/no-ext") ..
            "_" .. string.gsub(start_time_formated, ":", ".") ..
            "-" .. string.gsub(end_time_formated, ":", ".") .. "." .. output_format

        local output_path = utils.join_path(output_directory, output_filename)

        local args = { 'ffmpeg', '-ss', tostring(start_time_seconds), "-i",
            tostring(mp.get_property("path")), "-to",
            tostring(end_time_seconds - start_time_seconds) }

        for token in string.gmatch(video_args, "[^%s]+") do
            table.insert(args, token)
        end

        table.insert(args, output_path)
        --utils.subprocess_detached({args = args, playback_only = false})

        ov.data = "\n{\\an4}{\\b1}{\\fs20}{\\1c&H00FFFF&}" .. "Processing..."
        ov:update()

        local r = mp.command_native({
            name = "subprocess",
            playback_only = false,
            capture_stderr = true,
            capture_stdout = false,
            detach = false,
            args = args,
        })

        if r.status == 0 then
            print("Success! Video saved to: " .. output_path)
        else
            print("result: " .. r.stdout)
        end

        start_time_formated = nil
        start_time_seconds = nil
        end_time_seconds = nil
        end_time_formated = nil
        ov:remove()
    end
end

local showOnScreen = function()
    local st = (start_time_formated == nil and '' or start_time_formated)
    local et = (end_time_formated == nil and '' or end_time_formated)
    ov.data = "{\\an4}{\\b1}{\\fs20}{\\1c&H00FFFF&}" ..
        "Start:  " .. st .. "\n{\\an4}{\\b1}{\\fs20}{\\1c&H00FFFF&}" .. "End:  " .. et
    ov:update()
end

local fn_cut_start = function()
    start_time_seconds = 0
    start_time_formated = "00:00:00"
    mp.msg.info("START TIME: " .. start_time_seconds)
    showOnScreen()
end

local fn_cut_end = function()
    end_time_seconds = mp.get_property_number("duration")
    end_time_formated = mp.command_native({ "expand-text", "${duration}" })
    mp.msg.info("END TIME: " .. start_time_seconds)
    showOnScreen()
end

local fn_cut_left = function()
    start_time_seconds = mp.get_property_number("time-pos")
    start_time_formated = mp.command_native({ "expand-text", "${time-pos}" })
    mp.msg.info("START TIME: " .. start_time_seconds)
    showOnScreen()
end

local fn_cut_right = function()
    end_time_seconds = mp.get_property_number("time-pos")
    end_time_formated = mp.command_native({ "expand-text", "${time-pos}" })
    mp.msg.info("END TIME: " .. end_time_seconds)
    showOnScreen()
end

mp.register_script_message('cut-start', fn_cut_start)
mp.register_script_message('cut-end', fn_cut_end)
mp.register_script_message('cut-left', fn_cut_left)
mp.register_script_message('cut-right', fn_cut_right)
mp.register_script_message('cut-finish', fn_cut_finish)

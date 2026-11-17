----------------------------------------------------------------------------
--- Wallpaper changer module
--
-- @author Gerome Matilla &lt;gerome.matilla07@gmail.com&gt;
-- @copyright 2019 Gerome Matilla
-- @module wallchange
--
--- Nevermind this. Do what you want.
----------------------------------------------------------------------------

-- This module changes wallpaper based on declared time
-- It checks the difference between the current time and the next scheduled time
-- Then convert it to seconds to set it as a timeout value

local gears = require('gears')
local beautiful = require('beautiful')
local lgi = require('lgi')
local Gio = lgi.Gio
local function monotonic_time()
    return lgi.GLib.get_monotonic_time() / 1000000
end
local filesystem = gears.filesystem
local config = require('configuration.config')
local context = require('library.wallpaper-context')
local options = config.module.dynamic_wallpaper
local environment_enabled = options.solar == true or options.weather_enabled == true
local darkman_config = options.darkman_config or
    ((os.getenv('XDG_CONFIG_HOME') or (os.getenv('HOME') .. '/.config')) .. '/darkman/config.yaml')
local weather_service = options.weather_enabled and require('library.weather-service').default()
local weather_config = {
    providers = options.weather_providers or { 'open-meteo' },
    units = ((config.widget or {}).weather or {}).units or 'metric',
    update_interval = options.weather_interval or 300,
    max_age = options.weather_max_age or 7200,
}
local current_location


--  ========================================
--          Configuration
--      Change your preference here
--  ========================================

local wallpaper_name = ''

-- Global function used in lockscreen.lua
_G.get_wallpaper_name = function()
    return wallpaper_name
end

local set_wallpaper_name = function(name)
    wallpaper_name = name
end

local wall_config = {
    -- Wallpaper directory. The default is:
    -- local wall_config.wall_dir = os.getenv('HOME') .. 'Pictures/Wallpapers/'
    wall_dir = filesystem.get_configuration_dir() .. (config.module.dynamic_wallpaper.wall_dir or 'theme/wallpapers/'),

    -- If there's a picture format that awesome accepts and i missed
    -- (which i probably did) feel free to add it right here
    valid_picture_formats = config.module.dynamic_wallpaper.valid_picture_formats or { "jpg", "png", "jpeg" },

    -- Table mapping schedule to wallpaper filename
    wallpaper_schedule = config.module.dynamic_wallpaper.wallpaper_schedule or {
        ['00:00:00'] = 'am_12.jpg',
        ['01:00:00'] = 'am_01.jpg',
        ['02:00:00'] = 'am_02.jpg',
        ['03:00:00'] = 'am_03.jpg',
        ['04:00:00'] = 'am_04.jpg',
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
        ['13:00:00'] = 'pm_01.jpg',
        ['14:00:00'] = 'pm_02.jpg',
        ['15:00:00'] = 'pm_03.jpg',
        ['15:30:00'] = 'pm_03_30.jpg',
        ['16:00:00'] = 'pm_04.jpg',
        ['16:30:00'] = 'pm_04_30.jpg',
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
        ['23:00:00'] = 'pm_11.jpg'
    },

    -- Explicit opt-in to one panorama across the combined desktop.
    stretch = config.module.dynamic_wallpaper.stretch or false
}

--  ========================================
-- 				   Processes
--	    Don't touch it if it's working
--  ========================================

-- Get current time
local current_time = function()
    return os.date('%H:%M:%S')
end

-- Countdown variable
-- In seconds
local the_countdown = nil

-- Parse seconds to HH:MM:SS
local function parse_to_time(seconds)
    -- DST ruined me :(
    --return os.date("%H:%M:%S", seconds)

    local function format(str)
        while #str < 2 do
            str = '0' .. str
        end

        return str
    end

    local function convert(num)
        return format(tostring(num))
    end

    local hours = convert(math.floor(seconds / 3600))
    seconds = seconds - (hours * 3600)

    local minutes = convert(math.floor(seconds / 60))
    seconds = seconds - (minutes * 60)

    local sec = convert(math.floor(seconds))

    return (hours .. ':' .. minutes .. ':' .. sec)
end

-- Parse HH:MM:SS to seconds
local parse_to_seconds = function(time)
    -- Convert HH in HH:MM:SS
    local hour_sec = tonumber(string.sub(time, 1, 2)) * 3600

    -- Convert MM in HH:MM:SS
    local min_sec = tonumber(string.sub(time, 4, 5)) * 60

    -- Get SS in HH:MM:SS
    local get_sec = tonumber(string.sub(time, 7, 8))

    -- Return computed seconds
    return (hour_sec + min_sec + get_sec)
end

-- Get time difference
local time_diff = function(future, past)
    local diff = parse_to_seconds(future) - parse_to_seconds(past)
    if diff < 0 then
        diff = diff + (24 * 3600) --If time difference is negative, the future is meant for tomorrow
    end
    return diff
end

-- Returns a table containing all file paths in a directory
local function get_dir_contents(dir)
    local enumerator, err = Gio.File.new_for_path(dir):enumerate_children(
        'standard::name,standard::type', Gio.FileQueryInfoFlags.NONE
    )
    if not enumerator then
        gears.debug.print_error('Cannot list wallpapers in ' .. dir .. ': ' .. tostring(err))
        return {}
    end

    local files = {}
    for info in function() return enumerator:next_file() end do
        if info:get_file_type() == 'REGULAR' then
            files[#files + 1] = info:get_name()
        end
    end
    enumerator:close()
    return files
end

-- Returns a table of all the files that were one of the valid file formats
local function filter_files_by_format(files, valid_file_formats)
    local valid_files = {}
    for _, file in ipairs(files) do
        for _, format in ipairs(valid_file_formats) do
            if string.match(file, ".+%." .. format) ~= nil then
                table.insert(valid_files, file)
                break --No need to check other formats
            end
        end
    end

    return valid_files
end

-- Returns a table of files that contained any of the keywords, in the same order as the words themselves
local function find_files_containing_keywords(files, keywords)
    local found_files = {}

    for _, word in ipairs(keywords) do --Preserves keyword order inherently, conveniently
        for _, file in ipairs(files) do
            -- Check if file is word, contains word at beginning or contains word between 2 non-alphanumeric characters
            if file == word or string.find(file, "^" .. word .. "[^%a]") or string.find(file, "[^%a]" .. word .. "[^%a]") then
                found_files[word] = file
                break --Only return 1 file per word
            end
        end
    end

    return found_files
end

-- Turn an ordered list of files into a scheduled list of files
local function auto_schedule(wall_list)
    if #wall_list == 0 then
        return {}
    end

    local sched = {}
    for index, file in ipairs(wall_list) do
        local auto_time = parse_to_time(parse_to_seconds("24:00:00") * (index - 1) / #wall_list)
        sched[auto_time] = file
    end

    return sched
end

-- Reformat whatever schedule was specified into an actual schedule
if #wall_config.wallpaper_schedule == 0 then
    local count = 0
    -- Determine if empty or if manual schedule
    for _, _ in pairs(wall_config.wallpaper_schedule) do
        count = count + 1
    end

    if count == 0 then --Schedule is actually empty
        -- Get all pictures
        local pictures = filter_files_by_format(get_dir_contents(wall_config.wall_dir), wall_config
            .valid_picture_formats)

        --Sort pictures as sanely as possible
        local function order_pictures(a, b) --Attempts to mimic default sort but numbers aren't compared as strings
            if tonumber(a) ~= nil and tonumber(b) ~= nil then
                return tonumber(a) < tonumber(b)
            else
                return a < b
            end
        end
        table.sort(pictures, order_pictures)

        wall_config.wallpaper_schedule = auto_schedule(pictures)
    else --Schedule is manually timed
        -- Get times as list
        local ordered_times = {}
        for time, _ in pairs(wall_config.wallpaper_schedule) do
            table.insert(ordered_times, time)
        end

        -- Sort times using seconds as comparison
        local function order_time_asc(a, b)
            return parse_to_seconds(a) < parse_to_seconds(b)
        end
        table.sort(ordered_times, order_time_asc)

        -- Get ordered list of keywords from ordered times
        local keywords = {}
        for index, time in ipairs(ordered_times) do
            keywords[index] = wall_config.wallpaper_schedule[time]
        end

        -- Get any pictures that match keywords
        local pictures = filter_files_by_format(get_dir_contents(wall_config.wall_dir), wall_config
            .valid_picture_formats)
        pictures = find_files_containing_keywords(pictures, keywords)

        -- Replace keywords with files
        for _, time in ipairs(ordered_times) do
            local word = wall_config.wallpaper_schedule[time]
            if pictures[word] ~= nil then
                wall_config.wallpaper_schedule[time] = pictures[word]
            else --To avoid crashes, we'll remove entries with invalid keywords
                wall_config.wallpaper_schedule[time] = nil
            end
        end
    end
else --Schedule is list of keywords
    local keywords = wall_config.wallpaper_schedule

    -- Get any pictures that match keywords
    local pictures = filter_files_by_format(get_dir_contents(wall_config.wall_dir), wall_config.valid_picture_formats)
    pictures = find_files_containing_keywords(pictures, keywords)

    -- Order files by keyword (if a file was found for the keyword)
    local ordered_pictures = {}
    for _, word in ipairs(keywords) do
        local file = pictures[word]
        if file ~= nil then
            table.insert(ordered_pictures, file)
        end
    end

    wall_config.wallpaper_schedule = auto_schedule(ordered_pictures)
end

-- Set wallpaper
local set_wallpaper = function(path, target)
    if wall_config.stretch then
        gears.wallpaper.maximized(path, nil, false)
    elseif target then
        gears.wallpaper.maximized(path, target, false)
    else
        for s in screen do
            gears.wallpaper.maximized(path, s, false)
        end
    end
end

-- Update wallpaper (used by the manage_timer function)
-- I think the gears.wallpaper.maximized is too fast or being ran asynchronously
-- So the wallpaper is not being updated on awesome (re)start without this timer
-- We need some delay.
-- Hey it's working, so whatever
local applied_path
local update_wallpaper = function(wall_name)
    if not wall_name then return false, 'no readable wallpaper candidate' end
    local wall_dir = wall_config.wall_dir .. wall_name
    if applied_path == wall_dir then return true, false end
    local success, err = pcall(set_wallpaper, wall_dir)
    if not success then return false, err end
    applied_path = wall_dir

    -- Overwrite the default wallpaper
    -- This is important in case we add an extra monitor
    beautiful.wallpaper = wall_dir
    return true, true
end

-- Updates variables
local manage_timer = function()
    -- Get current time
    local time_now = parse_to_seconds(current_time())
    local solar, weather
    if environment_enabled then
        current_location = context.read_location(darkman_config)
        if current_location then
            if options.solar then solar = context.solar(os.time(), current_location) end
            if weather_service then weather = weather_service:peek(current_location, weather_config) end
        end
        if solar then time_now = solar.seconds end
    end

    local previous_time = ''      --Scheduled time that should activate now
    local next_time = ''          --Time that should activate next

    local first_time = '24:00:00' --First scheduled time registered (to be found)
    local last_time = '00:00:00'  --Last scheduled time registered (to be found)

    -- Find previous_time
    for time, _ in pairs(wall_config.wallpaper_schedule) do
        local parsed_time = parse_to_seconds(time)
        if previous_time == '' or parsed_time > parse_to_seconds(previous_time) then
            if parsed_time <= time_now then
                previous_time = time
            end
        end

        if parsed_time > parse_to_seconds(last_time) then
            last_time = time
        end
    end

    -- Previous time being blank = no scheduled time today. Therefore
    -- the last time was yesterday's latest time
    if previous_time == '' then
        previous_time = last_time
    end

    --Find next_time
    for time, _ in pairs(wall_config.wallpaper_schedule) do
        local parsed_time = parse_to_seconds(time)
        if next_time == '' or parsed_time < parse_to_seconds(next_time) then
            if parsed_time > time_now then
                next_time = time
            end
        end

        if parsed_time < parse_to_seconds(first_time) then
            first_time = time
        end
    end

    -- Next time being blank means that there is no scheduled times left for
    -- the current day. So next scheduled time is tomorrow's first time
    if next_time == '' then
        next_time = first_time
    end

    -- Update Wallpaper
    local name = context.choose(wall_config.wallpaper_schedule[previous_time],
        solar and solar.phase, context.condition(weather), options, function(candidate)
            return filesystem.file_readable(wall_config.wall_dir .. candidate)
        end)
    local updated, changed = update_wallpaper(name)
    if not updated then error(tostring(changed)) end
    if updated then
        set_wallpaper_name(name)
        if changed then awesome.emit_signal('module::change_background_wallpaper') end
    end

    -- Get the time difference to set as timeout for the wall_updater timer below
    the_countdown = environment_enabled and 60 or math.max(1, time_diff(next_time, current_time()))
end

local function refresh_weather(force)
    if not weather_service or not current_location then return end
    weather_service:fetch(current_location, weather_config, function(ok, _, _, cached)
        if ok and not cached then awesome.emit_signal('module::change_wallpaper') end
    end, { force = force })
end

local watchdog_interval = 120
local overdue_grace = 30
local retry_interval = 60
local last_success, next_update, last_error, last_error_key
local failures, recoveries = 0, 0
local wall_updater

local function update()
    local ok, err = xpcall(manage_timer, debug.traceback)
    local now = monotonic_time()
    if ok then
        if failures > 0 then gears.debug.print_warning('Wallpaper updates recovered') end
        last_success = now
        failures, last_error, last_error_key = 0, nil, nil
    else
        failures = failures + 1
        local error_key = tostring(err):match('^[^\n]+')
        if last_error_key ~= error_key then
            gears.debug.print_error('Wallpaper update failed: ' .. tostring(err))
        end
        last_error, last_error_key = err, error_key
    end
    local timeout = ok and the_countdown or retry_interval
    next_update = now + timeout
    wall_updater.timeout = timeout
    wall_updater:again()
end

local function request_weather(force)
    local ok, err = pcall(refresh_weather, force)
    if not ok then
        gears.debug.print_error('Wallpaper weather refresh failed: ' .. tostring(err))
    end
end

wall_updater = gears.timer {
    timeout = retry_interval,
    callback = function()
        awesome.emit_signal('module::change_wallpaper')
        request_weather()
    end,
}
awesome.connect_signal('module::change_wallpaper', update)
update()

local watchdog = gears.timer {
    timeout = watchdog_interval,
    autostart = true,
    callback = function()
        if not wall_updater.started or monotonic_time() > next_update + overdue_grace then
            recoveries = recoveries + 1
            gears.debug.print_warning('Wallpaper watchdog: recovering stopped or overdue scheduler')
            update()
            request_weather()
        end
    end,
}

local function apply(s)
    if type(beautiful.wallpaper) == 'string' and beautiful.wallpaper:sub(1, 1) == '/' then
        set_wallpaper(beautiful.wallpaper, s)
    end
end
screen.connect_signal('property::geometry', apply)
awesome.connect_signal('module::sleep_resumed', function()
    update()
    request_weather(true)
end)
gears.timer.delayed_call(request_weather)

local function status()
    local now = monotonic_time()
    return {
        started = wall_updater.started,
        watchdog_started = watchdog.started,
        healthy = wall_updater.started and watchdog.started and failures == 0
            and now <= next_update + overdue_grace,
        last_success_age = last_success and now - last_success,
        next_update_in = next_update - now,
        failures = failures,
        recoveries = recoveries,
        last_error = last_error,
    }
end

return { apply = apply, status = status }

-- Exercise the actual wallpaper module with a deterministic clock and Gio listing.
-- Test-only override of the read-only os.date function.
-- luacheck: ignore 122
local home = os.getenv('HOME') or ''
package.path = home .. '/.config/awesome/?.lua;' .. package.path
local wallpaper_dir = home .. '/.config/awesome/theme/wallpapers/'
local now = '14:30:00'
local current_wallpaper
local applied = {}
local panorama, spans = false, 0
local timer
local watchdog
local monotonic = 0
local render_error, missing_files
local errors, warnings = {}, {}
local timer_count = 0
local signals = {}
local beautiful = {}
local names = { 'am_08.jpg', 'pm_02.jpg', 'pm_03.jpg', 'AUTHORS' }

local Gio = {
    FileQueryInfoFlags = { NONE = 0 },
    File = {
        new_for_path = function(path)
            assert(path == wallpaper_dir, 'wallpaper directory changed unexpectedly')
            return {
                enumerate_children = function(_, attributes)
                    assert(attributes == 'standard::name,standard::type')
                    local index = 0
                    return {
                        next_file = function()
                            index = index + 1
                            local name = names[index]
                            if not name then return nil end
                            return {
                                get_name = function() return name end,
                                get_file_type = function() return name == 'AUTHORS' and 'DIRECTORY' or 'REGULAR' end,
                            }
                        end,
                        close = function() end,
                    }
                end,
            }
        end,
    },
}

package.loaded.lgi = {
    Gio = Gio,
    GLib = { get_monotonic_time = function() return monotonic * 1000000 end },
}
local timer_factory = setmetatable({ delayed_call = function(callback) callback() end }, {
    __call = function(_, settings)
        timer_count = timer_count + 1
        settings.started = settings.autostart or false
        function settings:again()
            self.started, self.restarted = true, true
            self.restarts = (self.restarts or 0) + 1
        end

        function settings:stop() self.started = false end

        if settings.autostart then watchdog = settings else timer = settings end
        return settings
    end,
})
package.loaded.gears = {
    filesystem = {
        get_configuration_dir = function() return home .. '/.config/awesome/' end,
        file_readable = function(path)
            if missing_files then return false end
            local input = io.open(path, 'r')
            if input then
                input:close(); return true
            end
            return false
        end,
    },
    wallpaper = {
        maximized = function(path, s, ignore_aspect)
            if render_error then error(render_error) end
            assert((s ~= nil) == (not panorama), 'Wallpaper scope does not match the panorama setting')
            assert(ignore_aspect == false, 'Wallpaper aspect ratio must be preserved')
            if s then applied[s] = path else spans = spans + 1 end
            current_wallpaper = path
        end
    },
    debug = {
        print_error = function(message) errors[#errors + 1] = message end,
        print_warning = function(message) warnings[#warnings + 1] = message end,
    },
    timer = timer_factory,
}
package.loaded.beautiful = beautiful
package.loaded['configuration.config'] = {
    module = {
        dynamic_wallpaper = {
            wall_dir = 'theme/wallpapers/',
            valid_picture_formats = { 'jpg' },
            wallpaper_schedule = {
                ['08:00:00'] = 'am_08.jpg',
                ['14:00:00'] = 'pm_02.jpg',
                ['15:00:00'] = 'pm_03.jpg',
            },
            stretch = false,
        }
    },
}

awesome = {
    connect_signal = function(name, callback) signals[name] = callback end,
    emit_signal = function(name) if signals[name] then signals[name]() end end,
}
local background_updates = 0
signals['module::change_background_wallpaper'] = function()
    background_updates = background_updates + 1
    assert(current_wallpaper == wallpaper_dir .. get_wallpaper_name(),
        'lockscreen signal must observe the newly selected wallpaper name')
end

local primary = { geometry = { width = 2880, height = 1800 } }
local external = { geometry = { width = 3440, height = 1440 } }
local geometry_handler
screen = setmetatable({
    connect_signal = function(name, handler)
        assert(name == 'property::geometry'); geometry_handler = handler
    end
}, {
    __call = function(_, _, previous)
        if not previous then return primary end
        if previous == primary then return external end
    end
})

local date = os.date
os.date = function(format, ...)
    if format == '%H:%M:%S' then return now end
    return date(format, ...)
end

local wallpaper = dofile(home .. '/.config/awesome/module/dynamic-wallpaper.lua')
assert(get_wallpaper_name() == 'pm_02.jpg', 'startup did not select the afternoon wallpaper')
assert(current_wallpaper == wallpaper_dir .. 'pm_02.jpg', 'startup did not apply the selected wallpaper')
assert(beautiful.wallpaper == current_wallpaper, 'new screens lost the selected wallpaper')
assert(timer.timeout == 1800 and timer.started, 'next wallpaper change was not scheduled')
assert(applied[primary] == current_wallpaper and applied[external] == current_wallpaper,
    'Each screen must get an independent aspect-preserving wallpaper')
local update_count = background_updates
signals['module::change_wallpaper']()
assert(background_updates == update_count, 'unchanged selections must not repaint or regenerate the lockscreen')
applied[external] = nil
external.geometry.height = 1080
geometry_handler(external)
assert(applied[external] == current_wallpaper, 'Resized screen lost its wallpaper')
local added = { geometry = { width = 1920, height = 1080 } }
wallpaper.apply(added)
assert(applied[added] == current_wallpaper, 'New screen did not get its own wallpaper')

now = '15:00:00'
timer.callback()
assert(get_wallpaper_name() == 'pm_03.jpg', 'scheduled change did not advance the wallpaper')
assert(current_wallpaper == wallpaper_dir .. 'pm_03.jpg', 'scheduled change did not apply the wallpaper')
assert(timer.restarted and timer.timeout == 17 * 3600, 'timer was not rescheduled for tomorrow')
assert(applied[primary] == current_wallpaper and applied[external] == current_wallpaper,
    'Scheduled changes must keep fitting every screen independently')

assert(wallpaper.status().healthy and watchdog.started, 'scheduler must expose healthy startup status')
assert(watchdog.timeout == 120, 'watchdog must check scheduler health every two minutes')
local restarts = timer.restarts
local original_timer_count = timer_count
watchdog.callback()
assert(timer.restarts == restarts, 'healthy long clock intervals must not trigger recovery')
timer:stop()
watchdog.callback()
assert(timer.started and wallpaper.status().recoveries == 1, 'watchdog did not recover a stopped timer')
assert(background_updates == update_count + 1, 'watchdog unnecessarily repainted unchanged wallpaper')
monotonic = monotonic + timer.timeout + 30
local before_grace = timer.restarts
watchdog.callback()
assert(timer.restarts == before_grace and wallpaper.status().healthy,
    'watchdog must allow the independent 30-second overdue grace')
monotonic = monotonic + 1
assert(not wallpaper.status().healthy, 'overdue health must not wait for the two-minute watchdog interval')
watchdog.callback()
assert(wallpaper.status().recoveries == 2 and wallpaper.status().healthy,
    'watchdog did not recover an overdue scheduler that still reports started')
assert(#warnings == 2, 'recoveries must be logged once per recovery')
assert(timer_count == original_timer_count, 'watchdog recovery created duplicate timers')

now = '08:00:00'
render_error = 'injected wallpaper rendering failure'
timer.callback()
assert(not wallpaper.status().healthy and wallpaper.status().failures == 1,
    'rendering failures must not be recorded as successful updates')
assert(timer.started and timer.timeout == 60, 'failure must arm a bounded retry')
assert(get_wallpaper_name() == 'pm_03.jpg', 'render failure discarded the previous wallpaper')
local error_count = #errors
timer.callback()
assert(#errors == error_count and wallpaper.status().failures == 2,
    'repeated identical failures must not flood the log')
render_error = nil
monotonic = monotonic + 60
timer.callback()
assert(wallpaper.status().healthy and wallpaper.status().last_error == nil,
    'successful retry did not clear failure status')
assert(get_wallpaper_name() == 'am_08.jpg', 'retry did not apply the current wallpaper')
assert(wallpaper.status().last_success_age == 0, 'success heartbeat was not updated')

missing_files = true
timer.callback()
assert(not wallpaper.status().healthy and wallpaper.status().last_error:match('no readable wallpaper'),
    'missing wallpaper assets must fail with a diagnostic')
assert(get_wallpaper_name() == 'am_08.jpg' and timer.timeout == 60,
    'missing assets must preserve the desktop and schedule a retry')
missing_files = false
now = '15:00:00'
signals['module::sleep_resumed']()
assert(wallpaper.status().healthy and timer.timeout == 17 * 3600,
    'resume did not recover failed updates and reset the schedule')
watchdog:stop()
assert(not wallpaper.status().healthy, 'status must detect an inactive watchdog')
watchdog:again()

local selection = require('library.wallpaper-context')
local choose = selection.choose
selection.choose = function() error('injected selection exception') end
timer.callback()
assert(not wallpaper.status().healthy and wallpaper.status().last_error:match('injected selection'),
    'unexpected selection exceptions must be contained and reported')
selection.choose = choose
timer.callback()
assert(wallpaper.status().healthy, 'selection exception prevented subsequent recovery')

missing_files = true
wallpaper = dofile(home .. '/.config/awesome/module/dynamic-wallpaper.lua')
assert(not wallpaper.status().healthy and timer.started and watchdog.started,
    'startup failure must still create a live scheduler and watchdog')
assert(wallpaper.status().last_success_age == nil, 'failed startup must not record a success')
missing_files = false
timer.callback()
assert(wallpaper.status().healthy, 'failed startup could not recover without reloading Awesome')

panorama = true
package.loaded['configuration.config'].module.dynamic_wallpaper.stretch = true
wallpaper = dofile(home .. '/.config/awesome/module/dynamic-wallpaper.lua')
assert(spans == 1, 'Explicit panorama mode must render once across the root desktop')
wallpaper.apply(external)
assert(spans == 2, 'Panorama mode must remain consistent when a screen requests wallpaper')

panorama = false
local options = package.loaded['configuration.config'].module.dynamic_wallpaper
options.stretch, options.solar, options.weather_enabled = false, true, true
options.weather_wallpapers = { night = { rain = 'am_08.jpg' } }
local context = require('library.wallpaper-context')
local read_location, solar = context.read_location, context.solar
local position = { latitude = 37.3, longitude = -121.8 }
local requests, weather_data, pending, force = 0, nil, nil, nil
local weather_error
context.read_location = function() return position end
context.solar = function() return { seconds = 15 * 3600, phase = 'night' } end
package.loaded['library.weather-service'] = {
    default = function()
        return {
            peek = function() return weather_data end,
            fetch = function(_, requested, weather_options, callback, settings)
                if weather_error then error('injected weather exception') end
                requests = requests + 1
                assert(requested == position, 'weather must use current darkman coordinates')
                assert(weather_options.update_interval == 300, 'wallpaper weather must refresh every five minutes')
                pending, force = callback, settings.force
            end,
        }
    end
}
local environmental_wallpaper = dofile(home .. '/.config/awesome/module/dynamic-wallpaper.lua')
assert(get_wallpaper_name() == 'pm_03.jpg', 'offline solar time must select the image before fetching weather')
assert(timer.timeout == 60 and requests == 1)
weather_error = true
timer.callback()
assert(environmental_wallpaper.status().healthy and timer.started and timer.timeout == 60,
    'weather exception must not affect the local scheduler')
assert(errors[#errors]:match('injected weather exception'), 'weather exception must be logged')
weather_error = false
weather_data = { icon_code = '10n' }
pending(true, weather_data, nil, false)
assert(get_wallpaper_name() == 'am_08.jpg', 'successful weather update must select a matching local variant')
weather_data = nil
signals['module::sleep_resumed']()
assert(get_wallpaper_name() == 'pm_03.jpg' and force, 'resume must apply local state immediately and retry weather')
position = { latitude = 12.97, longitude = 77.59 }
timer.callback()
position = nil
now = '14:30:00'
timer.callback()
assert(get_wallpaper_name() == 'pm_02.jpg', 'missing darkman config must restore the original clock schedule')
context.read_location, context.solar = read_location, solar

local listing = assert(io.popen("find '" .. wallpaper_dir:gsub("'", "'\\''") ..
    "' -maxdepth 1 -type f -printf '%f\\n'"))
names = {}
for name in listing:lines() do names[#names + 1] = name end
assert(listing:close())
package.loaded['gears.filesystem'] = package.loaded.gears.filesystem
local real_time = os.time
local timestamp = real_time({ year = 2026, month = 11, day = 15, hour = 0 })
os.time = function(fields) return fields and real_time(fields) or timestamp end
os.date = function(format, requested) return date(format, requested or timestamp) end

local function slots_for(schedule)
    local slots = {}
    for time, name in pairs(schedule) do
        local hour, minute, second = time:match('^(%d%d):(%d%d):(%d%d)$')
        slots[#slots + 1] = { seconds = hour * 3600 + minute * 60 + second, name = name }
    end
    table.sort(slots, function(first, second) return first.seconds < second.seconds end)
    return slots
end

local function expected_at(slots, seconds)
    local selected = slots[#slots].name
    for _, slot in ipairs(slots) do
        if slot.seconds <= seconds then selected = slot.name else break end
    end
    return selected
end

local function check_all_seen(schedule, seen)
    for _, name in pairs(schedule) do
        assert(seen[name], 'offline rotation skipped ' .. name)
    end
    for _, name in ipairs(names) do
        if name:match('%.jpg$') then
            assert(seen[name], 'local fallback image is not scheduled: ' .. name)
        end
    end
end

for _, profile in ipairs({ 'config', 'config_lenovo', 'config_imac' }) do
    local actual = dofile(home .. '/.config/awesome/configuration/' .. profile .. '.lua')
    package.loaded['configuration.config'] = actual
    local settings = actual.module.dynamic_wallpaper
    assert(settings.weather_interval == 300 and actual.widget.weather.update_interval == 300,
        'widget and wallpaper weather intervals must both be five minutes for ' .. profile)
    settings.solar, settings.weather_enabled, settings.stretch = false, false, false
    local schedule = settings.wallpaper_schedule
    local slots = slots_for(schedule)
    assert(#slots == 37, 'unexpected offline schedule length for ' .. profile)
    local midnight = real_time({ year = 2026, month = 11, day = 15, hour = 0 })
    timestamp = midnight
    dofile(home .. '/.config/awesome/module/dynamic-wallpaper.lua')
    local seen = {}
    for index, slot in ipairs(slots) do
        timestamp = midnight + slot.seconds
        timer.callback()
        assert(get_wallpaper_name() == slot.name, profile .. ' selected the wrong clock wallpaper')
        assert(current_wallpaper == wallpaper_dir .. slot.name, 'clock wallpaper was not applied')
        seen[slot.name] = true
        local next_seconds = slots[index + 1] and slots[index + 1].seconds or 86400 + slots[1].seconds
        assert(timer.timeout == next_seconds - slot.seconds, 'incorrect offline clock rotation timeout')
        timestamp = midnight + next_seconds - 1
        timer.callback()
        assert(get_wallpaper_name() == slot.name, 'clock wallpaper changed before its boundary')
        assert(timer.timeout == 1, 'rotation must wake at the next exact boundary')
    end
    timestamp = midnight + 86400
    timer.callback()
    assert(get_wallpaper_name() == slots[1].name, 'midnight did not wrap to the first wallpaper')
    check_all_seen(schedule, seen)

    settings.solar, settings.weather_enabled = true, true
    context.read_location = function() return { latitude = 37.3, longitude = -121.8 } end
    local cached
    local fetched_at
    package.loaded['library.weather-service'] = {
        default = function()
            return {
                peek = function(_, _, weather_options)
                    if cached and timestamp - fetched_at <= weather_options.max_age then return cached end
                end,
                fetch = function(_, _, _, callback) callback(false, nil, 'offline') end,
            }
        end
    }
    for _, month in ipairs({ 3, 6, 11, 12 }) do
        midnight = real_time({ year = 2026, month = month, day = 15, hour = 0 })
        timestamp = midnight
        dofile(home .. '/.config/awesome/module/dynamic-wallpaper.lua')
        local expected_slots = slots_for(schedule)
        seen = {}
        for elapsed = 0, 86340, 60 do
            timestamp = midnight + elapsed
            timer.callback()
            local position_now = assert(context.solar(timestamp, { latitude = 37.3, longitude = -121.8 }))
            local expected = expected_at(expected_slots, position_now.seconds)
            assert(get_wallpaper_name() == expected, 'offline solar rotation selected the wrong image')
            assert(current_wallpaper == wallpaper_dir .. expected, 'solar wallpaper was not applied')
            assert(timer.timeout == 60, 'offline solar scheduling must check once per minute without a network')
            seen[expected] = true
        end
        check_all_seen(schedule, seen)
    end

    timestamp = real_time({ year = 2026, month = 11, day = 15, hour = 12 })
    cached, fetched_at = { icon_code = '04d' }, timestamp
    timer.callback()
    local position_now = assert(context.solar(timestamp, { latitude = 37.3, longitude = -121.8 }))
    assert(get_wallpaper_name() == 'weather/cloudy/' .. position_now.phase .. '.jpg',
        'an offline session must still use fresh cached weather')
    timestamp = fetched_at + settings.weather_max_age + 1
    timer.callback()
    position_now = assert(context.solar(timestamp, { latitude = 37.3, longitude = -121.8 }))
    assert(get_wallpaper_name() == expected_at(slots, position_now.seconds),
        'expired weather must switch back to the offline solar schedule')
    timestamp = timestamp + 7200
    signals['module::sleep_resumed']()
    position_now = assert(context.solar(timestamp, { latitude = 37.3, longitude = -121.8 }))
    assert(get_wallpaper_name() == expected_at(slots, position_now.seconds),
        'offline wake must jump straight to the current scheduled image')

    for _, contents in ipairs({ '', 'lat: invalid\nlng: -121.8', 'lat: 89\nlng: 0' }) do
        context.read_location = function() return context.parse_location(contents) end
        cached = nil
        timestamp = real_time({ year = 2026, month = 6, day = 21, hour = 14, min = 30 })
        dofile(home .. '/.config/awesome/module/dynamic-wallpaper.lua')
        assert(get_wallpaper_name() == expected_at(slots, 14 * 3600 + 30 * 60),
            'offline startup without usable solar timing must use the local clock')
        assert(timer.timeout == 60, 'clock fallback must keep checking for restored coordinates')
        timestamp = timestamp + 3 * 3600
        signals['module::sleep_resumed']()
        assert(get_wallpaper_name() == expected_at(slots, 17 * 3600 + 30 * 60),
            'offline wake without usable solar timing must use the current clock slot')
        context.read_location = function() return { latitude = 37.3, longitude = -121.8 } end
        timer.callback()
        position_now = assert(context.solar(timestamp, { latitude = 37.3, longitude = -121.8 }))
        assert(get_wallpaper_name() == expected_at(slots, position_now.seconds),
            'restored coordinates must resume solar timing without a network')
    end
end

context.read_location, context.solar = read_location, solar
os.date, os.time = date, real_time
print('dynamic wallpaper tests passed: clock/solar rotations, weather, wake, watchdog and failure recovery')

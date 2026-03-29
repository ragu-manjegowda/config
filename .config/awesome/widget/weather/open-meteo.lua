local awful = require('awful')
local json = require('library.json')

local M = {}

local function to_icon_code(weather_code, is_day)
    local suffix = is_day and 'd' or 'n'

    if weather_code == 0 then
        return '01' .. suffix
    elseif weather_code == 1 or weather_code == 2 then
        return '02' .. suffix
    elseif weather_code == 3 then
        return '04' .. suffix
    elseif weather_code == 45 or weather_code == 48 then
        return '50' .. suffix
    elseif weather_code == 51 or weather_code == 53 or weather_code == 55 or weather_code == 56 or weather_code == 57 then
        return '09' .. suffix
    elseif weather_code == 61 or weather_code == 63 or weather_code == 65 or weather_code == 66 or weather_code == 67 then
        return '10' .. suffix
    elseif weather_code == 71 or weather_code == 73 or weather_code == 75 or weather_code == 77 or weather_code == 85 or weather_code == 86 then
        return '13' .. suffix
    elseif weather_code == 95 or weather_code == 96 or weather_code == 99 then
        return '11' .. suffix
    end

    return '...'
end

local function to_description(weather_code)
    local descriptions = {
        [0] = 'clear sky',
        [1] = 'mainly clear',
        [2] = 'partly cloudy',
        [3] = 'overcast',
        [45] = 'fog',
        [48] = 'depositing rime fog',
        [51] = 'light drizzle',
        [53] = 'moderate drizzle',
        [55] = 'dense drizzle',
        [56] = 'light freezing drizzle',
        [57] = 'dense freezing drizzle',
        [61] = 'slight rain',
        [63] = 'moderate rain',
        [65] = 'heavy rain',
        [66] = 'light freezing rain',
        [67] = 'heavy freezing rain',
        [71] = 'slight snow fall',
        [73] = 'moderate snow fall',
        [75] = 'heavy snow fall',
        [77] = 'snow grains',
        [80] = 'slight rain showers',
        [81] = 'moderate rain showers',
        [82] = 'violent rain showers',
        [85] = 'slight snow showers',
        [86] = 'heavy snow showers',
        [95] = 'thunderstorm',
        [96] = 'thunderstorm with hail',
        [99] = 'thunderstorm with hail',
    }

    return descriptions[weather_code] or 'unknown'
end

local function extract_hour(iso_time)
    if not iso_time then
        return '--:--'
    end

    local hour = tostring(iso_time):match('%d%d:%d%d')
    return hour or '--:--'
end

function M.is_available(location)
    return location.latitude and location.longitude
end

function M.fetch(location, config, callback)
    if not M.is_available(location) then
        callback(false, nil, 'missing_coordinates')
        return
    end

    local timezone = location.timezone or 'auto'
    local endpoint = string.format(
        'https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,weather_code,is_day&daily=sunrise,sunset&timezone=%s&forecast_days=1',
        tostring(location.latitude),
        tostring(location.longitude),
        tostring(timezone)
    )

    local script = string.format(
        [[
weather=$(curl -sf --connect-timeout 5 --max-time 12 %q)
if [ -n "$weather" ]; then
    printf "%%s" "$weather"
else
    printf "error"
fi
]],
        endpoint
    )

    awful.spawn.easy_async_with_shell(script, function(stdout)
        if not stdout or stdout:match('^%s*$') or stdout:match('^error$') then
            callback(false, nil, 'empty_response')
            return
        end

        local data = json.parse(stdout)
        if not data then
            callback(false, nil, 'parse_error')
            return
        end

        if not data.current or not data.daily then
            callback(false, nil, 'invalid_payload')
            return
        end

        local weather_code = tonumber(data.current.weather_code)
        local is_day = tonumber(data.current.is_day) == 1
        local sunrise = data.daily.sunrise and data.daily.sunrise[1] or nil
        local sunset = data.daily.sunset and data.daily.sunset[1] or nil

        callback(true, {
            location = location.name,
            country = location.country,
            sunrise = extract_hour(sunrise),
            sunset = extract_hour(sunset),
            temperature = data.current.temperature_2m,
            description = to_description(weather_code),
            icon_code = to_icon_code(weather_code, is_day),
        })
    end)
end

return M

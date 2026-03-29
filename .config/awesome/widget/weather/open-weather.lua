local awful = require('awful')
local json = require('library.json')

local M = {}

local function format_hour(timestamp)
    if not timestamp then
        return '--:--'
    end

    return os.date('%H:%M', timestamp)
end

function M.is_available(location, config)
    local weather = config.open_weather or {}
    local city_id = location.openweather_city_id or location.city_id

    return weather.key and weather.key ~= '' and city_id and tostring(city_id) ~= ''
end

function M.fetch(location, config, callback)
    local weather = config.open_weather or {}
    local city_id = location.openweather_city_id or location.city_id
    local units = config.units or 'metric'

    if not M.is_available(location, config) then
        callback(false, nil, 'missing_openweather_config')
        return
    end

    local script = string.format(
        [[
KEY=%q
CITY=%q
UNITS=%q
weather=$(curl -sf --connect-timeout 5 --max-time 12 "https://api.openweathermap.org/data/2.5/weather?APPID=${KEY}&id=${CITY}&units=${UNITS}")
if [ -n "$weather" ]; then
    printf "%%s" "$weather"
else
    printf "error"
fi
]],
        weather.key,
        tostring(city_id),
        units
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

        local code = tonumber(data.cod)
        if code and code ~= 200 then
            callback(false, nil, data.message or 'api_error')
            return
        end

        if not data.main or not data.weather or not data.weather[1] then
            callback(false, nil, 'invalid_payload')
            return
        end

        callback(true, {
            location = data.name or location.name,
            country = data.sys and data.sys.country or location.country,
            sunrise = format_hour(data.sys and data.sys.sunrise),
            sunset = format_hour(data.sys and data.sys.sunset),
            temperature = data.main.temp,
            description = data.weather[1].description,
            icon_code = data.weather[1].icon,
        })
    end)
end

return M

local awful = require('awful')
local json = require('library.json')

local M = {}

local function to_icon_code(weather_code)
    local code = tonumber(weather_code)

    if code == 113 then
        return '01d'
    elseif code == 116 then
        return '02d'
    elseif code == 119 or code == 122 then
        return '04d'
    elseif code == 143 or code == 248 or code == 260 then
        return '50d'
    elseif code == 176 or code == 263 or code == 266 or code == 293 or code == 296 or code == 299 or code == 302 or code == 305 or code == 308 then
        return '10d'
    elseif code == 200 or code == 386 or code == 389 or code == 392 or code == 395 then
        return '11d'
    elseif code == 179 or code == 182 or code == 185 or code == 227 or code == 230 or code == 281 or code == 284 or code == 311 or code == 314 or code == 317 or code == 320 or code == 323 or code == 326 or code == 329 or code == 332 or code == 335 or code == 338 or code == 350 or code == 353 or code == 356 or code == 359 or code == 362 or code == 365 or code == 368 or code == 371 or code == 374 or code == 377 then
        return '13d'
    end

    return '...'
end

function M.is_available(location)
    return location.wttr_query or location.name
end

function M.fetch(location, config, callback)
    local query = location.wttr_query or location.name
    if not query or query == '' then
        callback(false, nil, 'missing_query')
        return
    end

    local units = config.units or 'metric'
    local encoded_query = tostring(query):gsub('%s+', '+')
    local endpoint = 'https://wttr.in/' .. encoded_query .. '?format=j1'

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

        local current = data.current_condition and data.current_condition[1]
        local today = data.weather and data.weather[1]
        local astronomy = today and today.astronomy and today.astronomy[1]
        local weather_desc = current and current.weatherDesc and current.weatherDesc[1]

        if not current or not weather_desc then
            callback(false, nil, 'invalid_payload')
            return
        end

        local temperature = units == 'imperial' and current.temp_F or current.temp_C

        callback(true, {
            location = location.name,
            country = location.country,
            sunrise = astronomy and astronomy.sunrise or '--:--',
            sunset = astronomy and astronomy.sunset or '--:--',
            temperature = temperature,
            description = weather_desc.value,
            icon_code = to_icon_code(current.weatherCode),
        })
    end)
end

return M

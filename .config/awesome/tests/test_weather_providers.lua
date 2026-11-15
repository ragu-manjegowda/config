local home = assert(os.getenv('HOME'))
package.path = home .. '/.config/awesome/?.lua;' .. package.path
local response
package.loaded.awful = { spawn = { easy_async_with_shell = function(_, callback) callback(response) end } }
local json = require('library.json')
local providers = {
    require('widget.weather.open-meteo'),
    require('widget.weather.wttr'),
    (require('widget.weather.open-weather')),
}
local location = { latitude = 37.3, longitude = -121.8, name = 'Fixture', openweather_city_id = '1' }
local config = { open_weather = { key = 'fixture' } }
for _, provider in ipairs(providers) do
    for _, payload in ipairs({ '', 'error', '{broken', 'null', '12', '{}', '[]',
        '{"current":false,"daily":1}', '{"main":1,"weather":[false]}',
        '{"current_condition":[1],"weather":[false]}' }) do
        response = payload
        local completed = 0
        provider.fetch(location, config, function(ok)
            completed = completed + 1
            assert(not ok, 'malformed responses must not be accepted: ' .. payload)
        end)
        assert(completed == 1, 'invalid response must complete the request exactly once')
    end
end
for _, code in ipairs({ 80, 81, 82 }) do
    response = json.stringify({ current = { temperature_2m = 18, weather_code = code, is_day = 1 },
        daily = { sunrise = { '2026-11-15T06:47' }, sunset = { '2026-11-15T16:56' } } })
    providers[1].fetch(location, config, function(ok, data)
        assert(ok and data.icon_code == '10d', 'all rain-shower codes must select rain variants')
        assert(data.sunrise == '06:47' and data.sunset == '16:56')
    end)
end
print('weather provider tests passed')

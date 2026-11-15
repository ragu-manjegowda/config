local home = assert(os.getenv('HOME'))
package.path = home .. '/.config/awesome/?.lua;' .. package.path
local context = require('library.wallpaper-context')

local location = assert(context.parse_location('lat: 37.3\nlng: -121.8\nusegeoclue: false\n'))
assert(location.latitude == 37.3 and location.longitude == -121.8)
assert(location.timezone == 'auto')
assert(context.parse_location('lat: "12.97" # home\nlng: \'77.59\'').longitude == 77.59)
for _, contents in ipairs({ '', 'lat: 37', 'lat: 91\nlng: 0', 'lat: 0\nlng: -181',
    'lat: invalid\nlng: 0', 'lat: 0\nlng: .nan', 'lat: 0\nlat: 1\nlng: 0' }) do
    assert(context.parse_location(contents) == nil, 'invalid coordinates accepted: ' .. contents)
end
assert(context.read_location('/nonexistent/awesome-wallpaper-test') == nil)

local equator = { latitude = 0, longitude = 0 }
local equinox = assert(context.solar(1774008000, equator))
assert(equinox.phase == 'noon' and equinox.elevation > 85)
assert(math.abs(equinox.seconds - 13 * 3600) < 600)
local midnight = assert(context.solar(1774008000 + 12 * 3600, equator))
assert(midnight.phase == 'night' and midnight.elevation < -85)
local sunrise = assert(context.solar(1794754200, location))
assert(math.abs(sunrise.seconds - 7 * 3600) < 600, 'sunrise must follow local season, not a fixed clock time')
assert(sunrise.phase == 'dawn' or sunrise.phase == 'sunrise')
local summer = assert(context.solar(1782043200 + 6 * 3600, location))
local winter = assert(context.solar(1797854400 + 6 * 3600, location))
assert(math.abs(summer.seconds - winter.seconds) > 600, 'summer and winter daylight must differ')
assert(context.solar(1782043200, { latitude = 89, longitude = 0 }) == nil)
assert(context.solar(1797854400, { latitude = 89, longitude = 0 }) == nil)
assert(context.solar(1774008000, nil) == nil)
assert(context.solar(1774008000, { latitude = 90, longitude = 0 }) == nil)
local rotated = assert(context.solar(1774008000 + 3600, { latitude = 0, longitude = -15 }))
assert(math.abs(rotated.seconds - equinox.seconds) < 5, 'solar time must use UTC and longitude')
local before_midnight = assert(context.solar(1774008000 + 12 * 3600 - 1, equator))
assert(math.abs(before_midnight.seconds - midnight.seconds) < 60, 'UTC midnight must not jump the schedule')

for icon, expected in pairs({ ['01d'] = 'clear', ['02n'] = 'cloudy', ['04d'] = 'cloudy',
    ['09n'] = 'rain', ['10d'] = 'rain', ['11n'] = 'storm', ['13d'] = 'snow', ['50n'] = 'fog' }) do
    assert(context.condition({ icon_code = icon }) == expected)
end
assert(context.condition(nil) == nil and context.condition({ icon_code = '...' }) == nil)

local existing = {}
local function readable(name) return existing[name] == true end
local options = { weather_wallpapers = { night = { rain = 'rainy.jpg' } } }
existing['base.jpg'], existing['am_08.jpg'] = true, true
assert(context.choose('base.jpg', 'night', 'rain', options, readable) == 'base.jpg')
existing['phases/night.jpg'] = true
assert(context.choose('base.jpg', 'night', 'rain', options, readable) == 'phases/night.jpg')
existing['weather/rain/night.png'] = true
assert(context.choose('base.jpg', 'night', 'rain', options, readable) == 'weather/rain/night.png')
existing['weather/rain/base.jpg'] = true
assert(context.choose('base.jpg', 'night', 'rain', options, readable) == 'weather/rain/base.jpg')
existing['rainy.jpg'] = true
assert(context.choose('base.jpg', 'night', 'rain', options, readable) == 'rainy.jpg')
assert(context.choose('base.jpg', 'night', nil, options, readable) == 'phases/night.jpg')
assert(context.choose('base.jpg', nil, nil, options, readable) == 'base.jpg')
assert(context.choose('missing.jpg', nil, nil, options, readable) == 'am_08.jpg')
existing['am_08.jpg'] = nil
assert(context.choose('missing.jpg', nil, nil, options, readable) == nil)

existing = { ['base.jpg'] = true, ['weather/cloudy/morning.jpg'] = true,
    ['weather/cloudy/twilight.jpg'] = true }
assert(context.choose('base.jpg', 'late_morning', 'cloudy', {}, readable) == 'weather/cloudy/morning.jpg')
for _, phase in ipairs({ 'predawn', 'dawn', 'sunrise', 'golden_hour', 'sunset', 'twilight' }) do
    assert(context.choose('base.jpg', phase, 'cloudy', {}, readable) == 'weather/cloudy/twilight.jpg')
end
existing['weather/cloudy/sunset.png'] = true
assert(context.choose('base.jpg', 'sunset', 'cloudy', {}, readable) == 'weather/cloudy/sunset.png')
assert(context.choose('base.jpg', 'afternoon', 'cloudy', {}, readable) == 'base.jpg')
assert(context.choose('base.jpg', 'sunset', nil, {}, readable) == 'base.jpg')
assert(context.choose('base.jpg', nil, 'cloudy', {}, readable) == 'base.jpg')

print('wallpaper context tests passed')

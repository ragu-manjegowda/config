local home = assert(os.getenv('HOME'))
local directory = home .. '/.config/awesome/'
package.path = directory .. '?.lua;' .. package.path
package.loaded['gears.filesystem'] = {
    get_configuration_dir = function() return directory end,
}
local context = require('library.wallpaper-context')
local function readable(name)
    local input = io.open(directory .. 'theme/wallpapers/' .. name, 'rb')
    if not input then return false end
    input:close()
    return true
end
local phases = {
    'night', 'predawn', 'dawn', 'sunrise', 'morning', 'late_morning',
    'noon', 'afternoon', 'golden_hour', 'sunset', 'twilight',
}
for _, condition in ipairs({ 'cloudy', 'rain', 'storm', 'fog', 'snow' }) do
    for _, phase in ipairs(phases) do
        local expected = 'weather/' .. condition .. '/' .. phase .. '.jpg'
        assert(readable(expected), 'missing shipped wallpaper: ' .. expected)
        assert(context.choose('pm_03.jpg', phase, condition, {}, readable) == expected,
            'weather selection fell back instead of using ' .. expected)
    end
end
for _, phase in ipairs(phases) do
    assert(context.choose('pm_03.jpg', phase, nil, {}, readable) == 'pm_03.jpg')
    assert(context.choose('pm_03.jpg', phase, 'clear', {}, readable) == 'pm_03.jpg')
end
local location = { latitude = 37.3, longitude = -121.8 }
for _, month in ipairs({ 3, 6, 11, 12 }) do
    local midnight = os.time({ year = 2026, month = month, day = 15, hour = 0 })
    local observed = {}
    for minute = 0, 1439 do
        local solar = assert(context.solar(midnight + minute * 60, location))
        observed[solar.phase] = true
    end
    for _, phase in ipairs(phases) do
        assert(observed[phase], 'solar scheduler never reached ' .. phase .. ' in month ' .. month)
    end
end
local function only_base(name) return name == 'pm_03.jpg' end
assert(context.choose('pm_03.jpg', 'afternoon', 'cloudy', {}, only_base) == 'pm_03.jpg')
local additions = {
    ['01:00:00'] = 'am_01.jpg', ['02:00:00'] = 'am_02.jpg',
    ['03:00:00'] = 'am_03.jpg', ['04:00:00'] = 'am_04.jpg',
    ['15:30:00'] = 'pm_03_30.jpg', ['16:00:00'] = 'pm_04.jpg',
    ['16:30:00'] = 'pm_04_30.jpg', ['23:00:00'] = 'pm_11.jpg',
}
for _, profile in ipairs({ 'config', 'config_lenovo', 'config_imac' }) do
    local options = require('configuration.' .. profile).module.dynamic_wallpaper
    for time, name in pairs(additions) do
        assert(options.wallpaper_schedule[time] == name, profile .. ' missing ' .. time)
    end
    for _, name in pairs(options.wallpaper_schedule) do
        assert(readable(name), profile .. ' references missing image ' .. name)
    end
    for _, condition in ipairs({ 'rain', 'storm' }) do
        assert(context.choose('pm_10.jpg', 'night', condition, options, readable) ==
            'weather/' .. condition .. '/night.jpg')
    end
end
print('wallpaper assets: all weather phases, profile schedules and offline fallbacks passed')

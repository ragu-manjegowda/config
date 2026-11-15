local context = {}

local function finite(value)
    return type(value) == 'number' and value == value and math.abs(value) < math.huge
end

function context.parse_location(contents)
    if type(contents) ~= 'string' then return nil end
    local coordinates = {}
    for line in contents:gmatch('[^\r\n]+') do
        local key, value = line:match('^([%w_]+):%s*(.-)%s*$')
        if key == 'lat' or key == 'lng' then
            value = value:gsub('%s*#.*$', ''):gsub('^[\'"]', ''):gsub('[\'"]$', '')
            if coordinates[key] ~= nil then return nil end
            coordinates[key] = tonumber(value)
            if not finite(coordinates[key]) then return nil end
        end
    end
    if not finite(coordinates.lat) or math.abs(coordinates.lat) > 90
        or not finite(coordinates.lng) or math.abs(coordinates.lng) > 180 then return nil end
    return { latitude = coordinates.lat, longitude = coordinates.lng, timezone = 'auto' }
end

function context.read_location(path)
    local input = io.open(path, 'r')
    if not input then return nil end
    local contents = input:read(16384)
    input:close()
    return context.parse_location(contents)
end

function context.solar(timestamp, location)
    if not location or not finite(location.latitude) or not finite(location.longitude)
        or math.abs(location.latitude) >= 90 or math.abs(location.longitude) > 180 then return nil end
    local utc = os.date('!*t', timestamp)
    local leap = utc.year % 4 == 0 and (utc.year % 100 ~= 0 or utc.year % 400 == 0)
    local hour = utc.hour + utc.min / 60 + utc.sec / 3600
    local fraction = 2 * math.pi / (leap and 366 or 365) * (utc.yday - 1 + (hour - 12) / 24)
    local equation = 229.18 * (0.000075 + 0.001868 * math.cos(fraction)
        - 0.032077 * math.sin(fraction) - 0.014615 * math.cos(2 * fraction)
        - 0.040849 * math.sin(2 * fraction))
    local declination = 0.006918 - 0.399912 * math.cos(fraction) + 0.070257 * math.sin(fraction)
        - 0.006758 * math.cos(2 * fraction) + 0.000907 * math.sin(2 * fraction)
        - 0.002697 * math.cos(3 * fraction) + 0.001480 * math.sin(3 * fraction)
    local latitude = math.rad(location.latitude)
    local cosine = math.cos(math.rad(90.833)) / (math.cos(latitude) * math.cos(declination))
        - math.tan(latitude) * math.tan(declination)
    if cosine <= -1 or cosine >= 1 then return nil end
    local half_day = 4 * math.deg(math.acos(cosine))
    local solar_minutes = (hour * 60 + equation + 4 * location.longitude) % 1440
    local sunrise, sunset = 720 - half_day, 720 + half_day
    local virtual_hour
    if solar_minutes >= sunrise and solar_minutes < sunset then
        virtual_hour = 7 + 12 * (solar_minutes - sunrise) / (2 * half_day)
    else
        virtual_hour = (19 + 12 * ((solar_minutes - sunset) % 1440) / (1440 - 2 * half_day)) % 24
    end
    local elevation = math.deg(math.asin(math.max(-1, math.min(1,
        math.sin(latitude) * math.sin(declination)
        + math.cos(latitude) * math.cos(declination) * math.cos(math.rad(solar_minutes / 4 - 180))))))
    local rising = solar_minutes < 720
    local phase
    if elevation < -12 then phase = 'night'
    elseif elevation < -6 then phase = rising and 'predawn' or 'twilight'
    elseif elevation < -0.833 then phase = rising and 'dawn' or 'twilight'
    elseif elevation < 6 then phase = rising and 'sunrise' or 'sunset'
    elseif elevation < 12 then phase = rising and 'morning' or 'golden_hour'
    elseif virtual_hour < 11 then phase = 'morning'
    elseif virtual_hour < 12 then phase = 'late_morning'
    elseif virtual_hour < 14 then phase = 'noon'
    else phase = 'afternoon' end
    return { seconds = virtual_hour * 3600, phase = phase, elevation = elevation }
end

function context.condition(data)
    if type(data) ~= 'table' then return nil end
    local prefix = tostring(data.icon_code or ''):sub(1, 2)
    return ({ ['01'] = 'clear', ['02'] = 'cloudy', ['03'] = 'cloudy', ['04'] = 'cloudy',
        ['09'] = 'rain', ['10'] = 'rain', ['11'] = 'storm', ['13'] = 'snow', ['50'] = 'fog' })[prefix]
end

function context.choose(base, phase, condition, options, readable)
    options = options or {}
    local candidates = {}
    local variants = (options.weather_wallpapers or {})[phase] or {}
    if condition then
        candidates[#candidates + 1] = variants[condition]
        if base then candidates[#candidates + 1] = 'weather/' .. condition .. '/' .. base end
        if phase then
            for _, extension in ipairs({ 'jpg', 'png', 'jpeg' }) do
                candidates[#candidates + 1] = 'weather/' .. condition .. '/' .. phase .. '.' .. extension
            end
            local shared_phase = ({ late_morning = 'morning', predawn = 'twilight',
                dawn = 'twilight', sunrise = 'twilight', golden_hour = 'twilight',
                sunset = 'twilight' })[phase]
            if shared_phase then
                for _, extension in ipairs({ 'jpg', 'png', 'jpeg' }) do
                    candidates[#candidates + 1] = 'weather/' .. condition .. '/' .. shared_phase .. '.' .. extension
                end
            end
        end
    end
    if phase then
        for _, extension in ipairs({ 'jpg', 'png', 'jpeg' }) do
            candidates[#candidates + 1] = 'phases/' .. phase .. '.' .. extension
        end
    end
    candidates[#candidates + 1] = base
    candidates[#candidates + 1] = options.fallback_wallpaper or 'am_08.jpg'
    for _, candidate in ipairs(candidates) do
        if type(candidate) == 'string' and readable(candidate) then return candidate end
    end
end

return context

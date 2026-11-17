local service = {}

function service.new(dependencies)
    local now = dependencies.now or os.time
    local providers = dependencies.providers
    local load = dependencies.load or function() end
    local save = dependencies.save or function() end
    local memory, requests, failures = {}, {}, {}
    local instance = {}
    local cache_limit = 32
    local access_sequence = 0

    local function cache_get(cache, key)
        local entry = cache[key]
        if not entry then return nil end
        access_sequence = access_sequence + 1
        entry.accessed = access_sequence
        return entry.value
    end

    local function remember(cache, key, value)
        access_sequence = access_sequence + 1
        cache[key] = { value = value, accessed = access_sequence }
        local count, oldest_key, oldest_access = 0, nil, math.huge
        for candidate, entry in pairs(cache) do
            count = count + 1
            if entry.accessed < oldest_access then
                oldest_key, oldest_access = candidate, entry.accessed
            end
        end
        if count > cache_limit then cache[oldest_key] = nil end
    end

    local function identity(location, config)
        local latitude, longitude = tonumber(location.latitude), tonumber(location.longitude)
        local position
        if latitude and longitude then
            position = string.format('%.6f_%.6f', latitude, longitude)
        else
            position = tostring(location.openweather_city_id or location.city_id or location.wttr_query or location.name)
        end
        return (position .. '_' .. (config.units or 'metric')):gsub('[^%w_.%-]', '_')
    end

    local function valid_data(data)
        if type(data) ~= 'table' then return false end
        for _, field in ipairs({ 'location', 'country', 'sunrise', 'sunset' }) do
            if data[field] ~= nil and type(data[field]) ~= 'string' then return false end
        end
        local temperature = tonumber(data.temperature)
        return temperature ~= nil and temperature == temperature and math.abs(temperature) < math.huge
            and type(data.description) == 'string' and type(data.icon_code) == 'string'
            and data.icon_code:match('^%d%d[dn]$') ~= nil
    end

    local function valid(record, maximum_age)
        local timestamp = now()
        return type(record) == 'table' and type(record.fetched_at) == 'number'
            and record.fetched_at == record.fetched_at and record.fetched_at <= timestamp
            and timestamp - record.fetched_at <= maximum_age and valid_data(record.data)
    end

    function instance.peek(_instance, location, config)
        config = config or {}
        local key = identity(location, config)
        local record = cache_get(memory, key)
        if not record then
            local success, loaded = pcall(load, key)
            if success and type(loaded) == 'table' and loaded.key == key then
                remember(memory, key, loaded)
            end
            record = cache_get(memory, key)
        end
        if valid(record, config.max_age or 7200) then return record.data, record.fetched_at end
    end

    function instance:fetch(location, config, callback, options)
        config, options = config or {}, options or {}
        local key = identity(location, config)
        local cached, fetched_at = self:peek(location, config)
        if cached and not options.force and now() - fetched_at < (config.update_interval or 300) then
            callback(true, cached, nil, true)
            return
        end
        local failure = cache_get(failures, key)
        if failure and now() < failure.retry_at and not options.force then
            callback(options.allow_cached ~= false and cached ~= nil,
                options.allow_cached ~= false and cached or nil, 'retry_pending', cached ~= nil)
            return
        end
        local waiter = { callback = callback, allow_cached = options.allow_cached ~= false }
        if requests[key] then
            requests[key][#requests[key] + 1] = waiter
            return
        end
        local request = { waiter }
        requests[key] = request
        local order = config.providers or { 'open-meteo', 'wttr', 'open-weather' }
        if #order == 0 then order = { 'open-meteo', 'wttr', 'open-weather' } end
        local watchdog
        local finish, try_provider
        finish = function(data, error_message)
            if requests[key] ~= request then return end
            if watchdog then watchdog:stop() end
            if data then
                local record = { key = key, fetched_at = now(), data = data }
                remember(memory, key, record)
                failures[key] = nil
                pcall(save, key, record)
            else
                local count = failure and failure.count + 1 or 1
                remember(failures, key, {
                    count = count,
                    retry_at = now() + math.min(120, 15 * 2 ^ math.min(count - 1, 3)),
                })
            end
            local waiters = requests[key]
            requests[key] = nil
            local fallback = self:peek(location, config)
            for _, pending in ipairs(waiters) do
                local result = data or (pending.allow_cached and fallback or nil)
                pcall(pending.callback, result ~= nil, result, error_message, not data and result ~= nil)
            end
        end
        try_provider = function(index, last_error)
            if index > #order then
                finish(nil, last_error or 'unavailable'); return
            end
            local name = tostring(order[index]):lower():gsub('_', '-')
            if name == 'openmeteo' then name = 'open-meteo' end
            if name == 'openweather' then name = 'open-weather' end
            local provider = providers[name]
            if not provider then
                try_provider(index + 1, last_error); return
            end
            local available, supported = pcall(function()
                return not provider.is_available or provider.is_available(location, config)
            end)
            if not available or not supported then
                try_provider(index + 1, last_error); return
            end
            local completed = false
            local success = pcall(provider.fetch, location, config, function(ok, data, error_message)
                if completed or requests[key] ~= request then return end
                completed = true
                if ok and valid_data(data) then
                    data.provider = name
                    finish(data)
                else
                    try_provider(index + 1, error_message or 'invalid_payload')
                end
            end)
            if not success and not completed then
                completed = true
                try_provider(index + 1, 'provider_error')
            end
        end
        if dependencies.start_timeout then
            watchdog = dependencies.start_timeout(15 * #order, function()
                finish(nil, 'request_timeout')
                return false
            end)
        end
        try_provider(1)
    end

    return instance
end

local default
function service.default()
    if default then return default end
    local filesystem = require('gears.filesystem')
    local Gio = require('lgi').Gio
    local json = require('library.json')
    local directory = filesystem.get_cache_dir() .. 'weather/'
    default = service.new {
        start_timeout = require('gears.timer').start_new,
        providers = {
            ['open-meteo'] = require('widget.weather.open-meteo'),
            ['wttr'] = require('widget.weather.wttr'),
            ['open-weather'] = require('widget.weather.open-weather'),
        },
        load = function(key)
            local input = io.open(directory .. key .. '.json', 'r')
            if not input then return nil end
            local contents = input:read(65536)
            input:close()
            return json.parse(contents)
        end,
        save = function(key, record)
            filesystem.make_directories(directory)
            Gio.File.new_for_path(directory .. key .. '.json'):replace_contents(
                json.stringify(record), nil, false, Gio.FileCreateFlags.PRIVATE, nil)
        end,
    }
    return default
end

return service

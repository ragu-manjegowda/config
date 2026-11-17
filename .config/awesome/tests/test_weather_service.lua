local home = assert(os.getenv('HOME'))
package.path = home .. '/.config/awesome/?.lua;' .. package.path
local service = require('library.weather-service')
local json = require('library.json')
local clock = 10000
local storage, pending, calls, timers = {}, {}, {}, {}
local location = { latitude = 37.3, longitude = -121.8, timezone = 'auto' }
local config = { providers = { 'open-meteo' }, update_interval = 1200, max_age = 7200 }
local weather = { temperature = 18, icon_code = '04d', description = 'overcast' }
local dependencies = {
    now = function() return clock end,
    providers = {
        ['open-meteo'] = {
            fetch = function(position, _, callback)
                calls[#calls + 1] = position
                pending[#pending + 1] = callback
            end,
        }
    },
    load = function(key) return storage[key] and json.parse(storage[key]) end,
    save = function(key, record) storage[key] = json.stringify(record) end,
    start_timeout = function(_, callback)
        local timer = { callback = callback, stop = function(self) self.stopped = true end }
        timers[#timers + 1] = timer
        return timer
    end,
}
local instance = service.new(dependencies)
local results = {}
local function collect(ok, data, error_message, cached)
    results[#results + 1] = { ok = ok, data = data, error_message = error_message, cached = cached }
end
assert(instance:peek(location, config) == nil and #calls == 0)
instance:fetch(location, config, collect)
instance:fetch(location, config, collect)
assert(#calls == 1 and #results == 0, 'simultaneous consumers must share an asynchronous request')
pending[1](true, weather)
assert(#results == 2 and results[1].ok and results[1].data == weather)
assert(timers[1].stopped and next(storage) ~= nil)
instance:fetch(location, config, collect)
assert(#calls == 1 and results[3].cached, 'fresh cache must avoid network IO')
local restarted = service.new(dependencies)
assert(restarted:peek(location, config).icon_code == '04d', 'cache must survive Awesome restarts')
clock = clock + 1201
instance:fetch(location, config, collect)
pending[#pending](false, nil, 'offline')
assert(results[#results].ok and results[#results].cached, 'temporary outages must preserve usable weather')
local stored = storage[next(storage)]
assert(json.parse(stored).fetched_at == 10000, 'failure must not refresh cache age')
local call_count = #calls
instance:fetch(location, config, collect)
assert(#calls == call_count and results[#results].error_message == 'retry_pending')
clock = clock + 15
instance:fetch(location, config, collect)
assert(#calls == call_count + 1)
pending[#pending](false, nil, 'offline')
clock = clock + 29
instance:fetch(location, config, collect)
assert(#calls == call_count + 1)
clock = clock + 1
instance:fetch(location, config, collect)
assert(#calls == call_count + 2)
pending[#pending](false, nil, 'offline')
clock = clock + 59
instance:fetch(location, config, collect)
assert(#calls == call_count + 2)
clock = clock + 1
instance:fetch(location, config, collect)
assert(#calls == call_count + 3)
pending[#pending](false, nil, 'offline')
clock = clock + 119
instance:fetch(location, config, collect)
assert(#calls == call_count + 3)
clock = clock + 1
instance:fetch(location, config, collect)
assert(#calls == call_count + 4)
pending[#pending](true, weather)
instance:fetch(location, config, collect, { force = true, allow_cached = false })
pending[#pending](false, nil, 'offline')
assert(not results[#results].ok and not results[#results].data, 'widget refresh must respect allow_cached=false')
clock = clock + 7201
assert(instance:peek(location, config) == nil, 'overnight weather must expire even while offline')
instance:fetch(location, config, collect)
pending[#pending](false, nil, 'offline')
assert(not results[#results].ok)
assert(instance:peek({ latitude = 12.97, longitude = 77.59 }, config) == nil)
assert(instance:peek(location, { units = 'imperial' }) == nil)

local previous_storage = storage
storage = {}
for key in pairs(previous_storage) do storage[key] = '{broken' end
assert(service.new(dependencies):peek(location, config) == nil)
for key in pairs(previous_storage) do
    storage[key] = json.stringify({ key = key, fetched_at = clock + 100, data = weather })
end
assert(service.new(dependencies):peek(location, config) == nil, 'future cache timestamps must not be trusted')
for key in pairs(previous_storage) do
    storage[key] = json.stringify({ key = 'different-location', fetched_at = clock, data = weather })
end
assert(service.new(dependencies):peek(location, config) == nil)
storage = {}

instance = service.new(dependencies)
instance:fetch(location, config, collect)
local late_callback = pending[#pending]
timers[#timers].callback()
assert(results[#results].error_message == 'request_timeout')
clock = clock + 15
instance:fetch(location, config, collect)
late_callback(true, weather)
assert(instance:peek(location, config) == nil, 'late results from timed-out requests must be ignored')
pending[#pending](true, weather)
assert(instance:peek(location, config) == weather)

local fallback_calls = 0
local fallback = service.new {
    now = function() return clock end,
    save = function() error('read-only filesystem') end,
    providers = {
        ['open-meteo'] = { fetch = function(_, _, callback) callback(true, { temperature = 'invalid' }) end },
        wttr = { fetch = function(_, _, callback)
            fallback_calls = fallback_calls + 1; callback(true, weather)
        end },
    },
}
fallback:fetch(location, { providers = { 'unknown', 'open_meteo', 'wttr' } }, collect)
assert(results[#results].ok and fallback_calls == 1 and weather.provider == 'wttr')
assert(fallback:peek(location, {}) ~= nil, 'cache-write failure must not discard successful weather')

local default_calls = 0
local default_interval = service.new {
    now = function() return clock end,
    providers = { ['open-meteo'] = { fetch = function(_, _, callback)
        default_calls = default_calls + 1
        callback(true, weather)
    end } },
}
local default_config = { providers = { 'open-meteo' } }
default_interval:fetch(location, default_config, collect)
clock = clock + 299
default_interval:fetch(location, default_config, collect)
assert(default_calls == 1, 'default weather refresh must reuse cache before five minutes')
clock = clock + 1
default_interval:fetch(location, default_config, collect)
assert(default_calls == 2, 'default weather refresh must fetch again at five minutes')

print('weather service tests passed')

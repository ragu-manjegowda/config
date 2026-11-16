local home = assert(os.getenv('HOME'))
package.path = home .. '/.config/awesome/?.lua;' .. package.path
local service = require('library.weather-service')
local clock = 10000
local weather = { temperature = 18, icon_code = '04d', description = 'overcast' }
local config = { providers = { 'fixture' } }
local function location(index)
    return { latitude = 37, longitude = index }
end
local function ignore() end
local function must_succeed(ok) assert(ok, 'weather request unexpectedly failed') end

local instance = service.new {
    now = function() return clock end,
    providers = { fixture = { fetch = function(_, _, callback) callback(true, weather) end } },
}
for index = 1, 32 do instance:fetch(location(index), config, must_succeed) end
assert(instance:peek(location(1), config) == weather)
instance:fetch(location(33), config, must_succeed)
assert(instance:peek(location(1), config) == weather, 'recently read weather was evicted')
assert(instance:peek(location(2), config) == nil, 'least recently used weather was retained')
for _ = 1, 100 do
    instance:fetch(location(1), config, must_succeed, { force = true })
end
assert(instance:peek(location(3), config) == weather, 'updating an existing key consumed new slots')

local records = setmetatable({}, { __mode = 'v' })
local churn = service.new {
    now = function() return clock end,
    save = function(key, record) records[key] = record end,
    providers = { fixture = { fetch = function(_, _, callback) callback(true, weather) end } },
}
for index = 1, 1000 do churn:fetch(location(index), config, must_succeed) end
collectgarbage('collect')
collectgarbage('collect')
local retained = 0
for _ in pairs(records) do retained = retained + 1 end
assert(retained == 32, 'weather records or LRU metadata retained evicted locations')

local storage, loads, calls = {}, 0, 0
local persistent = service.new {
    now = function() return clock end,
    load = function(key) loads = loads + 1; return storage[key] end,
    save = function(key, record) storage[key] = record end,
    providers = { fixture = { fetch = function(_, _, callback)
        calls = calls + 1
        callback(true, weather)
    end } },
}
for index = 1, 33 do persistent:fetch(location(index), config, must_succeed) end
local previous_loads = loads
persistent:fetch(location(1), config, must_succeed)
assert(loads == previous_loads + 1 and calls == 33,
    'evicted weather must reload from disk without a network request')
assert(storage['37.000000_1.000000_metric'].accessed == nil,
    'LRU bookkeeping must not alter persisted weather records')

local failed_calls = 0
local failing = service.new {
    now = function() return clock end,
    providers = { fixture = { fetch = function(_, _, callback)
        failed_calls = failed_calls + 1
        callback(false, nil, 'offline')
    end } },
}
for index = 1, 32 do failing:fetch(location(index), config, ignore) end
failing:fetch(location(1), config, ignore)
assert(failed_calls == 32, 'recent failures must honor retry backoff')
failing:fetch(location(33), config, ignore)
failing:fetch(location(1), config, ignore)
assert(failed_calls == 33, 'recently used backoff entry was evicted')
failing:fetch(location(2), config, ignore)
assert(failed_calls == 34, 'least recently used backoff entry was not evicted')

local completed = 0
local pending
local concurrent = service.new {
    now = function() return clock end,
    providers = { fixture = { fetch = function(position, _, callback)
        if position.longitude == -1 then pending = callback else callback(true, weather) end
    end } },
}
local function completed_request(ok)
    must_succeed(ok)
    completed = completed + 1
end
concurrent:fetch(location(-1), config, completed_request)
for index = 1, 100 do concurrent:fetch(location(index), config, must_succeed) end
concurrent:fetch(location(-1), config, completed_request)
pending(true, weather)
assert(completed == 2, 'cache eviction discarded or duplicated in-flight request waiters')
assert(concurrent:peek(location(-1), config) == weather)

clock = clock + 7201
assert(persistent:peek(location(1), config) == nil, 'LRU access must not extend weather freshness')
print('weather cache tests passed: bounded records, LRU eviction, backoff, disk restore and active requests')

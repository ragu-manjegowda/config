#!/usr/bin/env luajit
package.path = '/usr/share/awesome/lib/?.lua;/usr/share/awesome/lib/?/init.lua;' .. package.path
local object = require('gears.object')
local key = '_secret_key_used_by_gears_object_in_Lua51'
local function gc()
    for _ = 1, 4 do collectgarbage('collect') end
end
local function proxy_count(func)
    return #assert(rawget(getfenv(func), key))
end

-- Existing objects and active connections must survive hot-loading.
local old_a, old_b = object(), object()
local old_hits = 0
local old_callback = function() old_hits = old_hits + 1 end
old_a:weak_connect_signal('test', old_callback)
old_b:weak_connect_signal('test', old_callback)
local legacy_count = proxy_count(old_callback)
local module_path = arg[1] or os.getenv('HOME') .. '/.config/awesome/library/luajit-weak-signals.lua'
local fix = dofile(module_path)
old_a:disconnect_signal('test', old_callback)
old_a:weak_connect_signal('test', old_callback)
gc()
old_a:emit_signal('test')
old_b:emit_signal('test')
assert(old_hits == 2, 'hot-loading lost an existing connection')
assert(proxy_count(old_callback) == legacy_count, 'hot-loading grew the proxy array')

-- A hierarchy callback changes widget repeatedly and has multiple signals.
local a, b = object(), object()
local hits = 0
local callback = function() hits = hits + 1 end
for _ = 1, 10000 do
    a:weak_connect_signal('redraw', callback)
    a:weak_connect_signal('layout', callback)
    a:disconnect_signal('redraw', callback)
    a:disconnect_signal('layout', callback)
    b:weak_connect_signal('redraw', callback)
    b:disconnect_signal('redraw', callback)
end
assert(proxy_count(callback) == 1, 'reconnections accumulate proxies')
a:weak_connect_signal('redraw', callback)
b:weak_connect_signal('redraw', callback)
gc()
a:emit_signal('redraw')
b:emit_signal('redraw')
assert(hits == 2, 'callback should survive while referenced')
a:disconnect_signal('redraw', callback)
a:emit_signal('redraw')
b:emit_signal('redraw')
assert(hits == 3, 'disconnect affected another emitter')

-- Weak signal registration must not keep an otherwise dead callback alive,
-- even when it closes over its emitter.
local emitter = object()
local weak = setmetatable({}, { __mode = 'v' })
do
    local captured = emitter
    local ephemeral = function() captured.observed = true end
    weak[1] = ephemeral
    emitter:weak_connect_signal('test', ephemeral)
end
gc()
assert(weak[1] == nil, 'weak registration retained the callback')
assert(next(emitter._signals.test.weak) == nil, 'dead registration did not disappear')
emitter:emit_signal('test')
assert(not emitter.observed, 'dead callback still ran')

-- A callback with an inherited environment must get its own proxy lifetime.
local owner = function() end
a:weak_connect_signal('owner', owner)
local inherited = setmetatable({}, { __index = getfenv(owner), __newindex = getfenv(owner) })
local child = function() end
setfenv(child, inherited)
a:weak_connect_signal('child', child)
assert(rawget(getfenv(child), key), 'callback reused inherited bookkeeping')
assert(getfenv(child)[key][1] ~= getfenv(owner)[key][1], 'callbacks share inherited proxy')
assert(fix.apply(), 'reapplying fix failed')
b:weak_connect_signal('layout', callback)
assert(proxy_count(callback) == 1, 'reapplying fix grew proxies')
print(
'PASS: 10,000 reconnect cycles; live and dead callbacks; multiple emitters; hot-loading; inherited environments; idempotence')

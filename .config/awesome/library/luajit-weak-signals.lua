-- Awesome's Lua 5.1 weak-signal shim ties a proxy userdata to each callback's
-- environment. Reconnecting a callback must reuse that proxy, not append one
-- forever. Load before creating widgets; replacing the helper upvalue also
-- fixes existing objects that copied the original weak_connect_signal method.
local object = require('gears.object')
local fix = {}
local proxy_key = '_secret_key_used_by_gears_object_in_Lua51'

local function callback_proxy(func)
    local env = getfenv(func)
    -- Do not borrow another callback's bookkeeping through __index.
    local proxies = rawget(env, proxy_key)
    if proxies and proxies[1] then
        -- Keep legacy proxies when hot-loading: other active weak connections
        -- may still reference them. A normal restart starts with one proxy.
        return proxies[1]
    end

    local proxy = newproxy(true)
    getmetatable(proxy).__gc = function() end
    if proxies then
        proxies[1] = proxy
    else
        local private_env = { [proxy_key] = { proxy } }
        setmetatable(private_env, { __index = env, __newindex = env })
        setfenv(func, private_env)
    end
    return proxy
end

function fix.apply()
    if _VERSION ~= 'Lua 5.1' then
        return false -- Lua 5.2+ uses callbacks directly and needs no shim.
    end
    local index = 1
    while true do
        local name = debug.getupvalue(object.weak_connect_signal, index)
        if not name then
            error('LuaJIT weak-signal fix: Awesome helper changed; review gears.object')
        end
        if name == 'make_the_gc_obey' then
            debug.setupvalue(object.weak_connect_signal, index, callback_proxy)
            return true
        end
        index = index + 1
    end
end

fix.apply()
return fix

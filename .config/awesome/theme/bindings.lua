local beautiful = require('beautiful')
local bindings = {}
local targets = setmetatable({}, { __mode = 'k' })
local callbacks = setmetatable({}, { __mode = 'k' })

local function apply(target, property, role)
    if type(role) == 'function' then
        target[property] = role(target, beautiful)
    else
        target[property] = beautiful[role]
    end
end

function bindings.bind(target, roles)
    local entry = targets[target] or {}
    targets[target] = entry
    for property, role in pairs(roles) do
        entry[property] = role
        apply(target, property, role)
    end
    return target
end

function bindings.on_change(target, callback)
    callbacks[target] = callback
    return target
end

function bindings.refresh()
    for target, entry in pairs(targets) do
        if target.valid ~= false then
            for property, role in pairs(entry) do apply(target, property, role) end
        end
    end
    for target, callback in pairs(callbacks) do callback(target) end
end

function bindings.widget(factory, roles)
    return function() return bindings.bind(factory(), roles) end
end

return bindings

local awful = require('awful')
local gears = require('gears')
local config = require('configuration.config')
local helper = gears.filesystem.get_configuration_dir() .. 'utilities/display-control'
local M = {}
local pending, order = {}, {}
local busy = false
local apply_timer

function M.output(s)
    s = s or awful.screen.focused()
    local outputs = s and s.outputs or {}
    local primary = config.display.primary.name
    if outputs[primary] then return primary end
    local names = {}
    for name in pairs(outputs) do names[#names + 1] = name end
    table.sort(names)
    return names[1] or primary
end

function M.read(output, callback)
    awful.spawn.easy_async({ helper, '--output', output, '-G' }, function(stdout, stderr, _, code)
        local value = tonumber(stdout)
        if code ~= 0 or not value or value ~= value or value < 0 or value > 100 then
            callback(nil, stderr)
        else
            callback(value)
        end
    end)
end

local function apply_next()
    if busy or #order == 0 then return end
    local output = table.remove(order, 1)
    local action = pending[output]
    pending[output] = nil
    busy = true
    local flag = action.relative and (action.value >= 0 and '-A' or '-U') or '-S'
    local value = action.relative and math.abs(action.value) or action.value
    awful.spawn.easy_async({ helper, '--output', output, flag, tostring(value) },
        function(stdout, stderr, _, code)
            busy = false
            if code == 0 and tonumber(stdout) then
                awesome.emit_signal('widget::brightness:changed', tonumber(stdout), output)
            else
                gears.debug.print_warning('Brightness update failed: ' .. tostring(stderr))
            end
            if action.show_osd and output == M.output() and code == 0 then
                awesome.emit_signal('module::brightness_osd:show', true)
            end
            if #order > 0 then apply_timer:again() end
        end)
end

apply_timer = gears.timer { timeout = 0.08, single_shot = true, callback = apply_next }

local function enqueue(output, value, relative, show_osd)
    local action = pending[output]
    if action and relative then
        action.value = action.value + value
    else
        if not action then order[#order + 1] = output end
        action = { value = value, relative = relative }
        pending[output] = action
    end
    action.show_osd = action.show_osd or show_osd
    if not busy then apply_timer:again() end
end

function M.set(output, value, show_osd)
    enqueue(output, math.max(5, math.min(100, value)), false, show_osd)
end

function M.adjust(delta)
    enqueue(M.output(), delta, true, true)
end

return M

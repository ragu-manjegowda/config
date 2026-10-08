-- Test the real lockscreen binding without a desktop, PAM, or authentication.
local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = root .. '?.lua;' .. package.path
local recovery = require('library.lockscreen-recovery-key')
local file = assert(io.open(root .. 'module/lockscreen.lua', 'r'))
local source = file:read('*a')
file:close()
local definition
for block in source:gmatch('awful%.key%s*(%b{})') do
    if block:find('back_door()', 1, true) then
        assert(not definition, 'There must be exactly one recovery binding')
        definition = block
    end
end
assert(definition, 'No lockscreen recovery binding found')
local stopped, recovered = 0, 0
local actions = {}
local environment = {
    recovery_key = recovery,
    type_again = true,
    back_door = function()
        recovered = recovered + 1
        actions[#actions + 1] = 'recover'
    end,
    awful = { key = function(args) return args end }
}
local chunk
if loadstring then
    chunk = assert(loadstring('return awful.key ' .. definition))
    setfenv(chunk, environment)
else
    chunk = assert(load('return awful.key ' .. definition, 'recovery-binding', 't', environment))
end
local binding = chunk()
local receiver = {
    stop = function()
        stopped = stopped + 1
        actions[#actions + 1] = 'stop'
    end
}
local aliases = { alt = 'Mod1', super = 'Mod4', shift = 'Shift', ctrl = 'Control' }
local function receive(chord)
    local parts = {}
    for part in chord:gmatch('[^+]+') do parts[#parts + 1] = part end
    local key = table.remove(parts)
    if key ~= binding.key or #parts ~= #binding.modifiers then return false end
    local modifiers = {}
    for _, part in ipairs(parts) do
        local modifier = aliases[part]
        if not modifier or modifiers[modifier] then return false end
        modifiers[modifier] = true
    end
    for _, expected in ipairs(binding.modifiers) do
        if not modifiers[expected] then return false end
    end
    binding.on_press(receiver)
    return true
end

assert(binding.key == 'Return' and #binding.modifiers == 4)
assert(receive(recovery.xdotool_chord()), 'The generated chord must reach the real lockscreen callback')
assert(stopped == 1 and recovered == 1, 'Recovery must stop its grab before invoking unlock')
assert(table.concat(actions, ',') == 'stop,recover', 'The password grab must be released first')
assert(receive('ctrl+alt+super+shift+Return'), 'Modifier ordering must not change matching')
assert(stopped == 2 and recovered == 2)
for _, mismatch in ipairs({
    'alt+super+shift+Return', 'ctrl+alt+shift+Return',
    'ctrl+alt+super+shift+KP_Enter', 'ctrl+alt+super+ctrl+Return'
}) do
    assert(not receive(mismatch), 'An incomplete or incorrect chord must not unlock')
end
assert(stopped == 2 and recovered == 2)
environment.type_again = false
assert(receive(recovery.xdotool_chord()))
assert(stopped == 2 and recovered == 2, 'Authentication cooldown must suppress recovery')
print('recovery key translation, real binding dispatch, mismatch and cooldown tests passed')

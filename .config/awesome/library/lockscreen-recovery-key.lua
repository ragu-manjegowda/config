-- Keep the lockscreen binding and command-line key injection in one contract.
local recovery = {
    modifiers = { 'Mod1', 'Mod4', 'Shift', 'Control' },
    key = 'Return'
}

function recovery.xdotool_chord()
    local names = { Mod1 = 'alt', Mod4 = 'super', Shift = 'shift', Control = 'ctrl' }
    local keys = {}
    for _, modifier in ipairs(recovery.modifiers) do
        keys[#keys + 1] = assert(names[modifier], 'Unsupported recovery modifier')
    end
    keys[#keys + 1] = recovery.key
    return table.concat(keys, '+')
end

return recovery

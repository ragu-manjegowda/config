local root = os.getenv('HOME')
package.path = root .. '/.config/awesome/?.lua;' ..
    root .. '/.config/awesome/?/init.lua;' .. package.path

local lifecycle = require('module.lockscreen-lifecycle')

local function screens(values)
    local index = 0
    return function()
        index = index + 1
        return values[index]
    end
end

assert(not lifecycle.is_visible(screens({
    { lockscreen = { visible = false } },
    { lockscreen_extended = { visible = false } },
})))
assert(lifecycle.is_visible(screens({
    { lockscreen = { visible = false } },
    { lockscreen_extended = { visible = true } },
})))

local exit_grabber = {}
assert(lifecycle.owns_keygrab(exit_grabber, exit_grabber))
assert(not lifecycle.owns_keygrab({}, exit_grabber))

assert(lifecycle.can_show_intruder(0, '/tmp/intruder.jpg\n', false, true))
assert(not lifecycle.can_show_intruder(1, '/tmp/intruder.jpg\n', false, true))
assert(not lifecycle.can_show_intruder(0, '', false, true))
assert(not lifecycle.can_show_intruder(0, '/tmp/intruder.jpg\n', true, true))
assert(not lifecycle.can_show_intruder(0, '/tmp/intruder.jpg\n', false, false))

local fingerprint = {}
assert(lifecycle.can_restart_fingerprint(true, fingerprint))
assert(not lifecycle.can_restart_fingerprint(false, fingerprint))
assert(not lifecycle.can_restart_fingerprint(true, nil))

print('lockscreen lifecycle tests passed')

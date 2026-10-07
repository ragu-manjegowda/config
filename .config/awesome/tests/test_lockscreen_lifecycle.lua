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
assert(not lifecycle.can_show_intruder(0, ' \n', false, true))
assert(lifecycle.can_show_intruder(0, '/tmp/intruder.jpg\n', false, true, 3, 3))
assert(not lifecycle.can_show_intruder(0, '/tmp/intruder.jpg\n', false, true, 2, 3),
    'A capture from a prior lock must not appear after unlocking and relocking')

local fingerprint = {}
assert(lifecycle.can_restart_fingerprint(true, fingerprint))
assert(not lifecycle.can_restart_fingerprint(false, fingerprint))
assert(not lifecycle.can_restart_fingerprint(true, nil))

local function check_lock_visibility(class, fullscreen, keep_mapped)
    local focused = { valid = true, class = class, fullscreen = fullscreen, minimized = false }
    local selected = { { selected = true }, { selected = true } }
    local previous_tag = lifecycle.hide_for_lock(focused, selected)
    assert(previous_tag == selected[2], 'the prior selected tag must still be restored')
    assert(focused.minimized == not keep_mapped, 'unexpected minimize-on-lock behavior')
    for _, t in ipairs(selected) do
        assert(t.selected == keep_mapped, 'lock preparation unexpectedly unmapped the client')
    end
    assert(focused.fullscreen == fullscreen, 'locking must not toggle fullscreen')
end

check_lock_visibility('Prisma-access-browser', true, true)
check_lock_visibility('prisma-access-browser', true, true)
check_lock_visibility('Prisma-access-browser', false, false)
check_lock_visibility('firefox', true, false)
check_lock_visibility(nil, false, false)
local empty_tag = { selected = true }
assert(lifecycle.hide_for_lock(nil, { empty_tag }) == empty_tag)
assert(not empty_tag.selected, 'locking without a focused client must retain tag hiding')

for _, key in ipairs({ 'lockscreen', 'lockscreen_extended' }) do
    local target = { visible = false }
    function target:geometry(value)
        self.x, self.y = value.x, value.y
        self.width, self.height = value.width, value.height
    end

    local s = {
        valid = true,
        geometry = { x = 2880, y = 0, width = 2880, height = 1800 },
        [key] = target,
    }
    assert(lifecycle.sync_geometry(s))
    s.geometry = { x = 2880, y = 0, width = 3440, height = 1440 }
    assert(lifecycle.sync_geometry(s))
    assert(target.x == 2880 and target.width == 3440 and target.height == 1440,
        'lockscreen must cover the whole output after a RandR resize')
    target.visible = true
    s.geometry = { x = 0, y = 0, width = 4300, height = 1800 }
    assert(lifecycle.sync_geometry(s))
    assert(target.x == 0 and target.width == 4300 and target.visible,
        'a visible lockscreen must follow scaling/repositioning without hiding')
    s.valid = false
    assert(not lifecycle.sync_geometry(s))
end
assert(not lifecycle.sync_geometry({ valid = true }))

print('lockscreen lifecycle tests passed')

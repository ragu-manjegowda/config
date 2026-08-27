#!/usr/bin/env lua

package.loaded.naughty = { suspended = false }

local root = os.getenv('HOME') .. '/.config/awesome/'
local suspension = dofile(root .. 'library/notification-suspension.lua')
local naughty = package.loaded.naughty

suspension.set('dnd', true)
assert(naughty.suspended, 'DND did not suspend notifications')
suspension.set('lockscreen', true)
suspension.set('center_open', true)
suspension.set('dnd', false)
assert(naughty.suspended, 'clearing DND incorrectly cleared lockscreen suspension')
assert(suspension.is_active('lockscreen'), 'lockscreen reason was lost')
suspension.set('lockscreen', false)
assert(naughty.suspended, 'clearing lockscreen incorrectly cleared center suspension')
suspension.set('center_open', false)
assert(not naughty.suspended, 'notifications remained suspended without reasons')

local reasons = { 'dnd', 'lockscreen', 'center_open' }
for mask = 0, 7 do
    for index, reason in ipairs(reasons) do
        suspension.set(reason, math.floor(mask / (2 ^ (index - 1))) % 2 == 1)
    end
    assert(naughty.suspended == (mask ~= 0),
        'suspension state was wrong for reason mask ' .. mask)
    for index, reason in ipairs(reasons) do
        local expected = math.floor(mask / (2 ^ (index - 1))) % 2 == 1
        assert(suspension.is_active(reason) == expected,
            reason .. ' state was wrong for reason mask ' .. mask)
    end
    for index = #reasons, 1, -1 do
        suspension.set(reasons[index], false)
    end
    assert(not naughty.suspended,
        'reverse clearing left notifications suspended for reason mask ' .. mask)
end

print('Notification suspension tests passed')

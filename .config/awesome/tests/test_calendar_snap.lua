package.path = os.getenv('HOME') .. '/.config/awesome/?.lua;' .. package.path

local snap = require('library.calendar-snap')

local function assert_offsets(actual, expected, message)
    assert(#actual == #expected, message .. ': offset count differs')
    for i, expected_offset in ipairs(expected) do
        assert(actual[i] == expected_offset,
            string.format('%s: offset %d was %s, expected %s', message, i, actual[i], expected_offset))
    end
end

local offsets, max_scroll, content_height = snap.build({ 68, 68, 68, 68 }, 5, 146)
assert_offsets(offsets, { 0, 34, 107, 141 }, 'equal-height card snaps')
assert(max_scroll == 141, 'last card did not clamp to the bottom boundary')
assert(content_height == 287, 'calendar content height was incorrect')

local current = offsets[1]
current = snap.step(current, offsets, 'down')
assert(current == 34, 'first downward step did not center the second card')
current = snap.step(current, offsets, 'down')
assert(current == 107, 'second downward step did not center the third card')
current = snap.step(current, offsets, 'down')
assert(current == 141, 'third downward step did not reach the last-card boundary')
assert(snap.step(current, offsets, 'down') == 141, 'scrolling below the last card changed the offset')

current = snap.step(current, offsets, 'up')
assert(current == 107, 'first upward step from the bottom did not center the previous card')
current = snap.step(current, offsets, 'up')
assert(current == 34, 'second upward step did not center the second card')
current = snap.step(current, offsets, 'up')
assert(current == 0, 'third upward step did not reach the first-card boundary')
assert(snap.step(current, offsets, 'up') == 0, 'scrolling above the first card changed the offset')

local mixed_offsets = snap.build({ 68, 54, 68 }, 5, 146)
assert_offsets(mixed_offsets, { 0, 27, 54 }, 'variable-height card snaps')

print('calendar snap tests passed')

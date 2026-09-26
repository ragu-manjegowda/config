local home = assert(os.getenv('HOME'))
local battery_alert = dofile(home .. '/.config/awesome/library/battery-alert.lua')

local check = battery_alert.new()
assert(check(30, 'discharging', 100) == nil)
assert(check(19, 'discharging', 101) == 'low', 'first low reading did not alert')
for _ = 1, 3 do
    assert(check(17, 'discharging', 101) == nil, 'one UPower update produced duplicate alerts')
end
assert(check(17, 'discharging', 102) == 'low', 'next UPower update lost its reminder')
assert(check(20, 'discharging', 103) == nil)
assert(check(19, 'unknown', 104) == nil)
assert(check(18, 'discharging', 102) == nil, 'unknown state rearmed the same update')
assert(check(19, 'discharging', 104) == 'low', 'new update after unknown state did not alert')
assert(check(5, 'discharging', 105) == 'critical', 'emergency action did not run')
assert(check(4, 'discharging', 105) == nil, 'emergency action repeated')
assert(check(5, 'discharging', 106) == nil, 'emergency action repeated on next update')

assert(check(19, 'charging', 107) == nil)
assert(check(19, 'discharging', 108) == 'low', 'new discharge did not alert')
assert(check(4, 'discharging', 109) == 'critical', 'new discharge did not rearm emergency action')

local other_screen = battery_alert.new()
assert(other_screen(4, 'discharging', 109) == 'critical', 'independent sessions share alert state')
assert(other_screen(4, 'discharging', 109) == nil)

print('battery alert lifecycle tests passed')

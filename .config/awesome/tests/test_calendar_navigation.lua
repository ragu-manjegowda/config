package.path = assert(os.getenv('HOME')) .. '/.config/awesome/?.lua;' .. package.path
local navigation = require('library.calendar-navigation')
local holidays = require('library.calendar-holidays')
local state = navigation.new { year = 2026, month = 10, day = 5 }

state:show('years')
local years = state:years()
assert(#years == 12 and years[1] == 2017 and years[12] == 2028)
assert(state:step(1) and state.year == 2038)
assert(state:select_year(2040) and state.mode == 'months')
assert(state:select_month(2) and state.mode == 'month' and state.day == nil)
assert(state:jump('2040-02-29') and state.day == 29)
assert(not state:jump('2100-02-29') and state.year == 2040,
    'An invalid Gregorian date must not change the displayed date')
assert(state:jump('2000-02-29'))
assert(state:jump(' 2051 ') and state.mode == 'months' and state.year == 2051)
assert(state:jump('2026-12') and state.month == 12 and state.day == nil)
assert(state:step(1) and state.year == 2027 and state.month == 1)
assert(state:step(-1) and state.year == 2026 and state.month == 12)
assert(state:jump('0001-01-01') and not state:step(-1))
assert(state:jump('9999-12-31') and not state:step(1))
state:select_year(9989)
state:show('years')
assert(state:step(1) and state:years()[1] == 9997 and not state:step(1),
    'The final partial year page must remain reachable without exceeding year 9999')
assert(not state:jump('10000') and not state:jump('2026-00-10') and not state:jump('not a date'))

local indexed = holidays.index { events = {
    { date = '2026-12-25', title = 'Christmas Day',                source = 'us' },
    { date = '2026-12-25', title = 'Christmas Day',                source = 'us' },
    { date = '2026-12-25', title = 'Company holiday <break>\nDay', source = 'work' },
    { date = 'invalid',    title = 'Invalid entry',                source = 'work' },
    { date = '2026-12-26', title = 'Meeting',                      source = 'meeting' },
} }
assert(#indexed['2026-12-25'] == 2 and indexed['2026-12-26'] == nil)
assert(holidays.tooltip(indexed['2026-12-25']) ==
    'US: Christmas Day\nWork: Company holiday <break> Day')
assert(navigation.key { year = 2026, month = 1, day = 2 } == '2026-01-02')
print('calendar navigation, Gregorian boundaries and holiday-label tests passed')

-- Calendar browsing state, independent of widgets, X11 and network sources.
local navigation = {}
local methods = {}

function navigation.days_in_month(year, month)
    if month == 2 then
        return (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and 29 or 28
    end
    return ({ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 })[month]
end

function navigation.valid_date(year, month, day)
    return year and year == math.floor(year) and year >= 1 and year <= 9999
        and month and month == math.floor(month) and month >= 1 and month <= 12
        and (not day or (day == math.floor(day) and day >= 1
            and day <= navigation.days_in_month(year, month)))
end

function navigation.key(date)
    return string.format('%04d-%02d-%02d', date.year, date.month, date.day)
end

function navigation.new(today)
    return setmetatable({ year = today.year, month = today.month, day = today.day, mode = 'month' },
        { __index = methods })
end

function methods:show(mode)
    assert(mode == 'month' or mode == 'months' or mode == 'years')
    self.mode = mode
end

function methods:select_year(year)
    if not navigation.valid_date(year, self.month) then return false end
    self.year, self.day, self.mode = year, nil, 'months'
    return true
end

function methods:select_month(month)
    if not navigation.valid_date(self.year, month) then return false end
    self.month, self.day, self.mode = month, nil, 'month'
    return true
end

function methods:select_date(year, month, day)
    if not navigation.valid_date(year, month, day) then return false end
    self.year, self.month, self.day, self.mode = year, month, day, 'month'
    return true
end

function methods:step(delta)
    if self.mode == 'month' then
        local index = (self.year - 1) * 12 + self.month - 1 + delta
        if index < 0 or index >= 9999 * 12 then return false end
        self.year, self.month = math.floor(index / 12) + 1, index % 12 + 1
    elseif self.mode == 'years' then
        local first = math.floor((self.year - 1) / 12) * 12 + 1
        local next_first = first + delta * 12
        if next_first < 1 or next_first > 9999 then return false end
        self.year = math.min(next_first + self.year - first, 9999)
    else
        local year = self.year + delta
        if year < 1 or year > 9999 then return false end
        self.year = year
    end
    self.day = nil
    return true
end

function methods:years()
    local first = math.floor((self.year - 1) / 12) * 12 + 1
    local years = {}
    for year = first, math.min(first + 11, 9999) do years[#years + 1] = year end
    return years
end

function methods:jump(text)
    text = text:match('^%s*(.-)%s*$')
    local year, month, day = text:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    if year then return self:select_date(tonumber(year), tonumber(month), tonumber(day)) end
    year, month = text:match('^(%d%d%d%d)%-(%d%d)$')
    if year then return self:select_date(tonumber(year), tonumber(month)) end
    if text:match('^%d+$') then return self:select_year(tonumber(text)) end
    return false
end

return navigation

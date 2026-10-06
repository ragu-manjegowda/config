-- Only display validated, bounded event labels; source/cache IO lives elsewhere.
local holidays = {}

function holidays.index(payload)
    local dates = {}
    if type(payload) ~= 'table' or type(payload.events) ~= 'table' then return dates end
    for _, event in ipairs(payload.events) do
        if type(event) == 'table' and type(event.date) == 'string'
            and event.date:match('^%d%d%d%d%-%d%d%-%d%d$')
            and type(event.title) == 'string' and event.title ~= '' and #event.title <= 1600
            and (event.source == 'us' or event.source == 'work') then
            local entries = dates[event.date] or {}
            dates[event.date] = entries
            local title = event.title:gsub('[\r\n\t]', ' ')
            local duplicate = false
            for _, existing in ipairs(entries) do
                if existing.source == event.source and existing.title == title then duplicate = true end
            end
            if not duplicate then entries[#entries + 1] = { title = title, source = event.source } end
        end
    end
    return dates
end

function holidays.tooltip(entries)
    local lines = {}
    for _, event in ipairs(entries or {}) do
        lines[#lines + 1] = (event.source == 'us' and 'US: ' or 'Work: ') .. event.title
    end
    return table.concat(lines, '\n')
end

return holidays

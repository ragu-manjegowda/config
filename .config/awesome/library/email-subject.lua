local subject = {}

local UTF8_CHARACTER = '[%z\1-\127\194-\244][\128-\191]*'

local function characters(text)
    local result = {}
    for character in text:gmatch(UTF8_CHARACTER) do
        table.insert(result, character)
    end
    return result
end

function subject.split(text, line_length)
    local chars = characters(text)
    if #chars <= line_length then
        return text, ''
    end

    local first_break = line_length
    for index = line_length, 1, -1 do
        if chars[index]:match('%s') then
            first_break = index
            break
        end
    end

    local first_end = first_break
    while first_end > 0 and chars[first_end]:match('%s') do
        first_end = first_end - 1
    end

    local second_start = first_break + 1
    while second_start <= #chars and chars[second_start]:match('%s') do
        second_start = second_start + 1
    end

    local second_end = math.min(#chars, second_start + line_length - 1)
    local truncated = second_end < #chars
    if truncated then
        second_end = second_start + line_length - 4
    end

    local first_line = table.concat(chars, '', 1, first_end)
    local second_line = table.concat(chars, '', second_start, second_end)
    if truncated then
        second_line = second_line:gsub('%s+$', '') .. '...'
    end

    return first_line, second_line
end


return subject

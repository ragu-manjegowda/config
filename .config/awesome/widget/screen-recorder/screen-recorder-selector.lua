local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local recorder_state = require('widget.screen-recorder.screen-recorder-state')

local selector = { active = false }

local function selection_color()
    local red, green, blue = tostring(beautiful.accent):match(
        '^#(%x%x)(%x%x)(%x%x)')
    assert(red and green and blue)
    return string.format(
        '%.3f,%.3f,%.3f,0.85',
        tonumber(red, 16) / 255,
        tonumber(green, 16) / 255,
        tonumber(blue, 16) / 255)
end

function selector.start(hide_overlays, completed)
    if selector.active then
        return
    end
    selector.active = true
    hide_overlays()

    gears.timer.start_new(0.1, function()
        awful.spawn.easy_async({
            'slop', '-t', '0', '-f', '%x %y %w %h',
            '-b', tostring(beautiful.xresources.apply_dpi(2)),
            '-c', selection_color()
        }, function(stdout, _, _, exit_code)
            selector.active = false
            if exit_code ~= 0 then
                completed(nil, 'cancelled')
                return
            end
            local root_width, root_height = root.size()
            local region = recorder_state.parse_selection(stdout, root_width, root_height)
            completed(region, region and nil or 'invalid')
        end)
        return false
    end)
end

return selector

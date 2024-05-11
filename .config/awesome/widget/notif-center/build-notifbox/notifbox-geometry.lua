local awful = require('awful')
local naughty = require('naughty')

local find_widget_in_wibox = function(wb, widgt)
    local function find_widget_in_hierarchy(h, widget)
        if h:get_widget() == widget then
            return h
        end
        local result

        for _, ch in ipairs(h:get_children()) do
            result = result or find_widget_in_hierarchy(ch, widget)
        end
        return result
    end
    local h = wb._drawable._widget_hierarchy
    return h and find_widget_in_hierarchy(h, widgt)
end


local focused = awful.screen.focused()
local h = find_widget_in_wibox(focused.top_panel, focused.music)
local _, _, _, height = h:get_matrix_to_device():transform_rectangle(0, 0, h:get_size())

naughty.notification({ message = tostring(height) })

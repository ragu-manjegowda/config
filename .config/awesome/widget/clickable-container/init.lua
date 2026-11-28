local bindings = require('theme.bindings')
local wibox = require('wibox')

local create_click_events = function(widget)
    local container = wibox.widget {
        widget,
        widget = wibox.container.background
    }

    -- Old and new widget
    local old_cursor, old_wibox

    -- Mouse hovers on the widget
    container:connect_signal(
        'mouse::enter',
        function()
            bindings.bind(container, { bg = 'groups_bg' })
            -- Hm, no idea how to get the wibox from this signal's arguments...
            local w = mouse.current_wibox
            if w then
                old_cursor, old_wibox = w.cursor, w
                w.cursor = 'hand1'
            end
        end
    )

    -- Mouse leaves the widget
    container:connect_signal(
        'mouse::leave',
        function()
            bindings.bind(container, { bg = 'leave_event' })
            if old_wibox then
                old_wibox.cursor = old_cursor
                old_wibox = nil
            end
        end
    )

    -- Mouse pressed the widget
    container:connect_signal(
        'button::press',
        function()
            bindings.bind(container, { bg = 'press_event' })
        end
    )

    -- Mouse releases the widget
    container:connect_signal(
        'button::release',
        function()
            bindings.bind(container, { bg = 'release_event' })
        end
    )

    return container
end

return create_click_events

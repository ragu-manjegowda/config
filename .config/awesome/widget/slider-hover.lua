-- Show that a slider can be dragged without wrapping or intercepting its
-- native button::press and mousegrabber handling.
local slider_hover = {}

function slider_hover.attach(slider)
    local owner, previous_cursor

    local function restore()
        if owner then
            owner.cursor = previous_cursor
            owner = nil
            previous_cursor = nil
        end
    end

    slider:connect_signal('mouse::enter', function()
        restore()
        local w = mouse.current_wibox
        if w then
            owner, previous_cursor = w, w.cursor
            w.cursor = 'hand1'
        end
    end)
    slider:connect_signal('mouse::leave', restore)
    awesome.connect_signal('control_center::visibility', function(visible)
        if not visible then restore() end
    end)
end

return slider_hover

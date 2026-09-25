local M = {}

-- Hiding a Naughty box alone leaves it in its placement stack. Detach the
-- popup without destroying its notification, which stays in Info Center.
function M.release(box, notification)
    if not box then return end
    box.visible = false

    local private = box._private
    if private and private.notification and private.notification[1] == notification and
        type(private.destroy_callback) == 'function' then
        pcall(private.destroy_callback)
    end
end

-- Naughty's box already knows how to position the whole popup stack, but it
-- only reflows automatically when screen geometry changes. Panel visibility
-- changes the workarea without changing that geometry.
function M.new(active_boxes, schedule)
    local pending = setmetatable({}, { __mode = 'k' })

    return function(s)
        if not s or not s.valid or pending[s] then return end
        pending[s] = true

        schedule(function()
            pending[s] = nil
            if not s.valid then return end

            for _, box in pairs(active_boxes) do
                if box.visible and box.screen == s then
                    -- Naughty's geometry handler repositions the entire stack
                    -- on this screen without recreating any notifications.
                    box:emit_signal('property::geometry')
                    return
                end
            end
        end)
    end
end

return M

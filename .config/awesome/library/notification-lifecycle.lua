local lifecycle = {}

function lifecycle.is_ignored(notification)
    return notification ~= nil and notification.ignore == true
end

function lifecycle.should_play_sound(notification, handled, do_not_disturb)
    if not notification or handled[notification] then
        return false
    end
    handled[notification] = true
    return not do_not_disturb and not lifecycle.is_ignored(notification)
end

function lifecycle.invoke_default(notification, reason)
    if not notification then
        return false
    end

    if notification._private and notification._private._unique_sender then
        notification:destroy(reason)
        return true
    end

    if type(notification.run) ~= 'function' then
        return false
    end

    local destroyed = false
    local destroyed_handler = function()
        destroyed = true
    end
    notification:connect_signal('destroyed', destroyed_handler)
    pcall(notification.run, notification)
    if not destroyed then
        notification:destroy(reason)
    end
    notification:disconnect_signal('destroyed', destroyed_handler)
    return true
end

function lifecycle.watch_suspension(notification, on_suspend)
    local handler = function()
        if notification.suspended then
            on_suspend(notification)
        end
    end
    notification:connect_signal('property::suspended', handler)
    return handler
end

return lifecycle

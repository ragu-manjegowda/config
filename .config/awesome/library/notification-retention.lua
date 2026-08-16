local retention = {
    limit = 10,
}

function retention.priority(notification)
    local ok, urgency, priority, hints = pcall(function()
        return notification.urgency,
            notification._private.retention_priority,
            notification._private.freedesktop_hints
    end)
    if not ok then
        return 0
    end

    local explicit = tonumber(priority or
        (hints and hints['x-awesome-retention-priority']))
    if explicit then
        return explicit
    end
    if urgency == 'critical' then
        return 2
    end
    return 0
end

function retention.eviction_index(notifications)
    if #notifications == 0 then
        return nil
    end

    local candidate = 1
    local priority = retention.priority(notifications[candidate])

    for index = 2, #notifications do
        local current = retention.priority(notifications[index])
        if current < priority then
            candidate = index
            priority = current
        end
    end

    return candidate
end


return retention

local retention = {
    limit = 10,
}

function retention.priority(notification)
    local ok, urgency, priority, hints, app_name = pcall(function()
        return notification.urgency,
            notification._private.retention_priority,
            notification._private.freedesktop_hints,
            notification.app_name
    end)
    if not ok then
        return 0
    end

    if urgency == 'critical' then
        return 2
    end

    if tostring(app_name):lower() == 'blueman' then
        return -1
    end

    local explicit = tonumber(priority or
        (hints and hints['x-awesome-retention-priority']))
    if explicit then
        return math.max(0, math.min(1, explicit))
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

function retention.new(on_evict)
    local store = {
        entries = {},
        by_notification = setmetatable({}, { __mode = 'k' }),
    }

    function store:add(notification)
        local existing = self.by_notification[notification]
        if existing then
            return existing
        end

        local entry = {
            notification = notification,
            cards = {},
        }
        self.entries[#self.entries + 1] = entry
        self.by_notification[notification] = entry

        local evicted
        if #self.entries > retention.limit then
            local notifications = {}
            for index, current in ipairs(self.entries) do
                notifications[index] = current.notification
            end
            evicted = self.entries[retention.eviction_index(notifications)]
            self:remove(evicted.notification)
            if on_evict then
                on_evict(evicted)
            end
        end

        return self.by_notification[notification], evicted
    end

    function store:get(notification)
        return self.by_notification[notification]
    end

    function store:set_card(notification, view, card)
        local entry = self.by_notification[notification]
        if entry then
            entry.cards[view] = card
        end
    end

    function store:remove(notification)
        local entry = self.by_notification[notification]
        if not entry then
            return nil
        end

        self.by_notification[notification] = nil
        for index, current in ipairs(self.entries) do
            if current == entry then
                table.remove(self.entries, index)
                break
            end
        end
        return entry
    end

    return store
end

return retention

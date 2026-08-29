local screen_tag_state = {}

function screen_tag_state.collect(source_screen)
    local by_client = {}
    local states = {}

    for _, tag in ipairs(source_screen.tags) do
        for _, client in ipairs(tag:clients()) do
            local state = by_client[client]
            if not state then
                state = { client = client, tag_indices = {} }
                by_client[client] = state
                states[#states + 1] = state
            end
            state.tag_indices[#state.tag_indices + 1] = tag.index
        end
    end

    return states
end

function screen_tag_state.map(target_screen, tag_indices)
    local tags = {}
    for _, index in ipairs(tag_indices) do
        local tag = target_screen.tags[index]
        if not tag then
            return nil
        end
        tags[#tags + 1] = tag
    end
    return tags
end

function screen_tag_state.fit_geometry(geometry, source, target)
    local width = math.min(geometry.width, target.width)
    local height = math.min(geometry.height, target.height)
    local relative_x = geometry.x - source.x
    local relative_y = geometry.y - source.y
    local max_x = math.max(0, target.width - width)
    local max_y = math.max(0, target.height - height)

    return {
        x = target.x + math.max(0, math.min(relative_x, max_x)),
        y = target.y + math.max(0, math.min(relative_y, max_y)),
        width = width,
        height = height
    }
end

return screen_tag_state

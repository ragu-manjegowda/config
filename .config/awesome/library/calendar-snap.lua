local snap = {}

function snap.build(row_heights, spacing, viewport_height)
    local content_height = 0
    for i, row_height in ipairs(row_heights) do
        content_height = content_height + row_height
        if i < #row_heights then
            content_height = content_height + spacing
        end
    end

    local max_scroll = math.max(0, content_height - viewport_height)
    local offsets = {}
    local row_offset = 0

    for i, row_height in ipairs(row_heights) do
        local centered = row_offset - (viewport_height - row_height) / 2
        local offset = math.max(0, math.min(centered, max_scroll))
        if #offsets == 0 or math.abs(offset - offsets[#offsets]) > 0.5 then
            table.insert(offsets, offset)
        end
        row_offset = row_offset + row_height
        if i < #row_heights then
            row_offset = row_offset + spacing
        end
    end

    return offsets, max_scroll, content_height
end

function snap.step(current_offset, offsets, direction)
    if direction == 'up' then
        for i = #offsets, 1, -1 do
            if offsets[i] < current_offset - 0.5 then
                return offsets[i]
            end
        end
    elseif direction == 'down' then
        for _, offset in ipairs(offsets) do
            if offset > current_offset + 0.5 then
                return offset
            end
        end
    end

    return current_offset
end


return snap

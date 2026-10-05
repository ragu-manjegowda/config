-- Screen geometry/workarea are already pixels. DPI applies only to design
-- dimensions, never to the screen's available height a second time.
local beautiful = require('beautiful')
local base = require('wibox.widget.base')
local center_geometry = {}

function center_geometry.bounds(s)
    local geometry = s.geometry
    local area = s.workarea or geometry
    -- The theme gap is already in pixels. Tiled outer edges and Naughty's
    -- popup spacing use two gaps outside the workarea's top-panel edge.
    local gap = 2 * (beautiful.useless_gap or beautiful.xresources.apply_dpi(5, s))
    local top = math.ceil(math.max(area.y, geometry.y) + gap)
    local bottom = math.min(area.y + area.height, geometry.y + geometry.height) - gap
    return {
        x = area.x + gap,
        y = top,
        width = math.max(1, area.width - 2 * gap),
        height = math.max(1, bottom - top),
    }
end

function center_geometry.width(s)
    return math.min(beautiful.xresources.apply_dpi(s.geometry.width / 6, s), center_geometry.bounds(s).width)
end

function center_geometry.bind(panel, s, alignment)
    local function place(p)
        local bounds = center_geometry.bounds(s)
        p.x = alignment == 'top' and bounds.x + math.floor((bounds.width - p.width) / 2)
            or bounds.x + bounds.width - p.width
        p.y = bounds.y
    end
    local function refresh()
        if s.valid == false then return end
        local bounds = center_geometry.bounds(s)
        local width = center_geometry.width(s)
        panel.minimum_width = width
        panel.maximum_width = width
        panel.maximum_height = bounds.height
        panel.width = width
        panel.height = math.min(panel.height, bounds.height)
        place(panel)
    end
    refresh()
    panel.placement = place
    panel:connect_signal('property::visible', function()
        if panel.visible then refresh() end
    end)
    for _, signal in ipairs({ 'property::geometry', 'property::workarea', 'property::dpi' }) do
        s:connect_signal(signal, refresh)
    end
    local removed
    removed = function(removed_screen)
        if removed_screen ~= s then return end
        for _, signal in ipairs({ 'property::geometry', 'property::workarea', 'property::dpi' }) do
            s:disconnect_signal(signal, refresh)
        end
        screen.disconnect_signal('removed', removed)
    end
    screen.connect_signal('removed', removed)
end

-- Keep the existing Info Center sections and their own list scrolling. Their
-- viewport allowances share the height left after the panel margins/spacing.
function center_geometry.fit_sections(panel, s, sections)
    local dpi = beautiful.xresources.apply_dpi
    local allowance = math.max(0, panel.maximum_height - dpi(32, s) - dpi(10, s) * (#sections - 1)) / #sections
    local context = { screen = s, dpi = beautiful.xresources.get_dpi(s) }
    local allocations = {}
    local available = allowance * #sections
    local required, flexible = 0, 0
    for _, section in ipairs(sections) do
        if section.set_viewport_height then
            if section.set_viewport_context then section:set_viewport_context(panel.width - dpi(32, s), context) end
            local _, height = base.fit_widget(panel.widget, context, section, panel.width - dpi(32, s), 100000)
            local header_and_margins = math.max(0, height - section:get_viewport_height())
            local minimum = section.get_minimum_viewport_height and math.ceil(section:get_minimum_viewport_height()) or 0
            local wanted = math.max(minimum, allowance - header_and_margins)
            allocations[#allocations + 1] = { section = section, minimum = minimum, extra = wanted - minimum }
            available = available - header_and_margins
            required = required + minimum
            flexible = flexible + wanted - minimum
        end
    end
    available = math.max(0, available)
    local minimum_ratio = required > 0 and math.min(1, available / required) or 1
    local extra_ratio = flexible > 0 and math.min(1, math.max(0, available - required) / flexible) or 0
    for _, entry in ipairs(allocations) do
        entry.section:set_viewport_height(math.floor(entry.minimum * minimum_ratio + entry.extra * extra_ratio))
    end
end

return center_geometry

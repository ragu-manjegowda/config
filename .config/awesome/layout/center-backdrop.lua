-- Keep the visible top panel interactive while center overlays catch outside clicks.
local center_backdrop = {}

function center_backdrop.show(backdrop, s)
    local top = s.top_panel
    local inset = top and top.visible and top.height or 0

    backdrop.x = s.geometry.x
    backdrop.y = s.geometry.y + inset
    backdrop.width = s.geometry.width
    backdrop.height = s.geometry.height - inset
    backdrop.visible = true
end

return center_backdrop

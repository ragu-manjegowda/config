-- Keep the four center popups mutually exclusive, regardless of whether
-- they were opened from the wibar, a keybinding, or another screen.
local manager = {}
local active_panel

function manager.open(panel)
    if active_panel and active_panel ~= panel then
        active_panel:hide_dashboard()
    end
    active_panel = panel
end

function manager.close(panel)
    if active_panel == panel then
        active_panel = nil
    end
end

function manager.hide()
    if active_panel then active_panel:hide_dashboard() end
end

function manager.active()
    return active_panel
end

screen.connect_signal('removed', function(removed)
    if active_panel and active_panel.screen == removed then
        active_panel:hide_dashboard()
    end
end)

return manager

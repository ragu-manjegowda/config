mp.register_script_message('gui-probe', function(generation)
    local menu = Menu:is_open()
    local current = menu and menu.current
    local items = {}
    for _, item in ipairs(current and current.items or {}) do
        items[#items + 1] = { title = item.title, selectable = item.selectable ~= false }
    end
    mp.set_property_native('user-data/gui-probe', {
        generation = generation,
        menu = menu and menu.type or '',
        query = current and current.search and current.search.query or '',
        items = items,
        selected = current and current.selected_index or 0,
        ax = menu and menu.ax or 0,
        ay = menu and menu.ay or 0,
        bx = menu and menu.bx or 0,
        by = menu and menu.by or 0,
        width = display.width,
        height = display.height,
    })
end)

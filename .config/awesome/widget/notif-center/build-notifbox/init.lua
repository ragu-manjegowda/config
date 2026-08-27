local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi

local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/notif-center/icons/'

local new_empty_notifbox = require('widget.notif-center.build-notifbox.empty-notifbox')

local manager = {
    views = setmetatable({}, { __mode = 'k' }),
}

function manager.each_view()
    return pairs(manager.views)
end

function manager.remove_view(view)
    manager.views[view] = nil
    awesome.emit_signal('widget::notif-center:view_removed', view)
end

function manager.new_view()
    local empty_notifbox = new_empty_notifbox()
    local removed_cards = setmetatable({}, { __mode = 'k' })
    local view = {
        remove_notifbox_empty = true,
    }

    view.notifbox_layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        empty_notifbox
    }

    local function show_empty_state()
        view.remove_notifbox_empty = true
        view.notifbox_layout:reset()
        view.notifbox_layout:insert(1, empty_notifbox)
    end

    view.remove_card = function(card, dismiss)
        if removed_cards[card] then
            return
        end
        removed_cards[card] = true
        if dismiss then
            card:emit_signal('widget::dismiss')
        end
        card:emit_signal('widget::removed')
        view.notifbox_layout:remove_widgets(card, true)
        if #view.notifbox_layout.children == 0 then
            show_empty_state()
        end
    end

    view.clear = function()
        for _, card in ipairs(view.notifbox_layout.children) do
            if card ~= empty_notifbox and not removed_cards[card] then
                removed_cards[card] = true
                card:emit_signal('widget::removed')
            end
        end
        show_empty_state()
    end

    view.add_notification = function(n)
        if #view.notifbox_layout.children == 1 and view.remove_notifbox_empty then
            view.notifbox_layout:reset()
            view.remove_notifbox_empty = false
        end

        local notifbox_color = beautiful.transparent
        if n.urgency == 'critical' then
            notifbox_color = (n.bg or beautiful.bg_urgent or beautiful.accent) .. '66'
        end
        local notif_icon = n.icon or n.app_icon or widget_icon_dir .. 'new-notif.svg'
        local notifbox_box = require('widget.notif-center.build-notifbox.notifbox-builder')
        local card = notifbox_box(
            n,
            notif_icon,
            n.title,
            n.message,
            n.app_name,
            notifbox_color,
            view
        )
        view.notifbox_layout:insert(1, card)
        return card
    end

    manager.views[view] = true
    awesome.emit_signal('widget::notif-center:view_added', view)
    return view
end

function manager.clear_all()
    for view in manager.each_view() do
        view.clear()
    end
end

return manager

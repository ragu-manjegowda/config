local naughty = require('naughty')
local beautiful = require('beautiful')
local gears = require('gears')
local rgba = gears.color.to_rgba_string
local icon_view = require('widget.notification-icon')
local config = gears.filesystem.get_configuration_dir()
local symbolic = config .. 'widget/email/icons/email-unread.svg'
local photo = gears.surface.load_uncached(config .. 'widget/playerctl/icons/default.png')
local view = require('widget.notif-center.build-notifbox').new_view()

local function check_icon(note, expected, is_symbolic)
    local popup = icon_view.popup(note).widget
    local key = is_symbolic and 'symbolic_source' or 'original_image'
    assert(popup._private[key] == expected, 'Popup did not use the highest-priority source')
    local card = view.add_notification(note, os.time())
    local found = false
    for _, child in ipairs(card:get_all_children()) do
        if child._private[key] == expected then found = true end
    end
    assert(found, 'Notification history did not use the same artwork as the popup')
    view.remove_card(card, false)
    note:destroy()
end

check_icon(naughty.notification { icon = photo, app_icon = symbolic }, photo, false)
check_icon(naughty.notification { image = photo, app_icon = symbolic }, photo, false)
check_icon(naughty.notification { app_icon = 'file://' .. symbolic }, symbolic, true)
check_icon(naughty.notification { image = symbolic }, symbolic, true)

local function open(urgency)
    local note = naughty.notification {
        title = 'Theme fixture title', message = 'Theme fixture message', urgency = urgency, timeout = 0,
    }
    for _, draw in ipairs(root.drawins()) do
        local box = draw:get_wibox()
        if box and box.notification == note then
            box:emit_signal('mouse::enter')
            return box
        end
    end
    error('Missing real ' .. urgency .. ' notification popup')
end

local normal, low = open('normal'), open('low')

local function check_text(box)
    local count = 0
    local function visit(widget, ink)
        ink = widget.fg or ink
        if widget.get_text and (widget.text == box.notification.title or widget.text == box.notification.message) then
            local override = (widget.markup or ''):match("color=['\"]([^'\"]+)")
            assert(rgba(override or ink) == rgba(beautiful.fg_normal), 'Popup text kept the old foreground')
            count = count + 1
        end
        for _, child in ipairs(widget.children or {}) do visit(child, ink) end
    end
    assert(box.visible, 'Repainting closed the notification')
    local backdrop = box.notification.urgency == 'normal' and beautiful.bg_focus or beautiful.background
    assert(rgba(box.widget.bg) == rgba(backdrop), 'Popup kept the old background')
    visit(box.widget, box.fg)
    assert(count == 2, 'Did not exercise both real notification text widgets')
end

return function()
    check_text(normal)
    check_text(low)
    local directory = os.getenv('XDG_DATA_HOME') .. '/icons/' .. beautiful.icon_theme .. '/32x32/apps/'
    local note = naughty.notification { app_icon = 'GUI-NOTIFY' }
    assert(note.icon == directory .. 'gui-notify.svg', 'Named notification used the wrong icon theme')
    note:destroy()
    local action = {}
    naughty.emit_signal('request::action_icon', action, 'app_icon', { id = 'gui-action' })
    assert(action.icon == directory .. 'gui-action.svg', 'Action used the wrong icon theme')
end

local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi

local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/notif-center/icons/'

local empty_notifbox = require('widget.notif-center.build-notifbox.empty-notifbox')

local notif_core = {}

notif_core.remove_notifbox_empty = true

notif_core.notifbox_layout = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(5),
    empty_notifbox
}

notif_core.reset_notifbox_layout = function()
    notif_core.notifbox_layout:reset()
    notif_core.notifbox_layout:insert(1, empty_notifbox)
    notif_core.remove_notifbox_empty = true
    -- Update notification count
    if _G.update_notif_count then
        _G.update_notif_count(0)
    end
end

local notifbox_add = function(n, notif_icon, notifbox_color)
    if #notif_core.notifbox_layout.children == 1 and notif_core.remove_notifbox_empty then
        notif_core.notifbox_layout:reset(notif_core.notifbox_layout)
        notif_core.remove_notifbox_empty = false
    end

    local notifbox_box = require('widget.notif-center.build-notifbox.notifbox-builder')
    notif_core.notifbox_layout:insert(
        1,
        notifbox_box(
            n,
            notif_icon,
            n.title,
            n.message,
            n.app_name,
            notifbox_color
        )
    )

    -- Update notification count
    if _G.update_notif_count then
        local count = #notif_core.notifbox_layout.children
        _G.update_notif_count(count)
    end
end

-- Expose notifbox_add for adding notifications to the info center
-- All notifications are now kept alive (D-Bus connection active) for action invocation
notif_core.add_notification = function(n)
    local notifbox_color = beautiful.transparent
    if n.urgency == 'critical' then
        notifbox_color = n.bg .. '66'
    end

    local notif_icon = n.icon or n.app_icon
    if not notif_icon then
        notif_icon = widget_icon_dir .. 'new-notif' .. '.svg'
    end

    notifbox_add(n, notif_icon, notifbox_color)
end

return notif_core

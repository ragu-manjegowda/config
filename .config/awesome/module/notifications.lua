local gears = require('gears')
local wibox = require('wibox')
local awful = require('awful')
local ruled = require('ruled')
local naughty = require('naughty')
local menubar = require('menubar')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local animation = require("library.tween")
local cst = require("naughty.constants")
local retention = require('library.notification-retention')
local lifecycle = require('library.notification-lifecycle')
local notif_manager = require('widget.notif-center.build-notifbox')
local displaying_error = false

-- Keep strong references to notification popup widgets so they are not
-- garbage-collected while naughty still tracks them internally (the
-- internal by_position table uses weak references).  Entries are removed
-- in the 'destroyed' signal handler below.
local active_boxes = {}
local active_animations = {}
local popup_order = {}
local suspension_handlers = setmetatable({}, { __mode = 'k' })
local MAX_VISIBLE_POPUPS = 3

local function remove_from_popup_order(notification)
    for index = #popup_order, 1, -1 do
        if popup_order[index] == notification then
            table.remove(popup_order, index)
            return
        end
    end
end

local function contains_text(value, needle)
    return tostring(value or ''):lower():find(needle, 1, true) ~= nil
end

local function is_prisma_teams_web_notification(n)
    return tostring(n.app_name or ''):lower() == 'prisma browser' and
        contains_text(n.message, 'teams.microsoft.com')
end

local function normalize_notification_urgency(n)
    if is_prisma_teams_web_notification(n) then
        n.urgency = 'normal'
    end
end

local function preferred_notification_screen()
    if screen.count() > 1 then
        for candidate in screen do
            if candidate ~= screen.primary and candidate.valid then
                return candidate
            end
        end
    end

    local preferred_ok, preferred = pcall(awful.screen.preferred)
    if preferred_ok and preferred and preferred.valid then
        return screen.primary or preferred
    end
    return screen.primary or screen[1]
end

local function remove_cards(entry)
    if not entry then
        return
    end
    for view, card in pairs(entry.cards) do
        view.remove_card(card, false)
        entry.cards[view] = nil
    end
end

local notification_store = retention.new(function(evicted)
    remove_cards(evicted)
    pcall(function()
        evicted.notification:destroy(naughty.notification_closed_reason.expired)
    end)
end)

local function track_notification(n)
    if lifecycle.is_ignored(n) then
        n:destroy(naughty.notification_closed_reason.expired)
        return nil
    end
    return notification_store:add(n)
end

local function add_entry_to_view(entry, view)
    if not entry.cards[view] then
        notification_store:set_card(
            entry.notification,
            view,
            view.add_notification(entry.notification)
        )
    end
end

local function add_to_notification_center(n)
    local entry = notification_store:get(n) or track_notification(n)
    if not entry then
        return
    end
    for view in notif_manager.each_view() do
        add_entry_to_view(entry, view)
    end
end

awesome.connect_signal('widget::notif-center:view_added', function(view)
    for _, entry in ipairs(notification_store.entries) do
        add_entry_to_view(entry, view)
    end
end)

awesome.connect_signal('widget::notif-center:view_removed', function(view)
    for _, entry in ipairs(notification_store.entries) do
        entry.cards[view] = nil
    end
end)

awesome.connect_signal('widget::notif-center:clear_all', function()
    local notifications = {}
    for _, entry in ipairs(notification_store.entries) do
        notifications[#notifications + 1] = entry.notification
    end
    notif_manager.clear_all()
    for _, notification in ipairs(notifications) do
        pcall(function()
            notification:destroy(naughty.notification_closed_reason.expired)
        end)
    end
end)

naughty.connect_signal('property::active', function()
    local newest = naughty.active[#naughty.active]
    if not newest then
        return
    end

    track_notification(newest)
    gears.timer.delayed_call(function()
        local entry = notification_store:get(newest)
        if entry and newest.suspended and not next(entry.cards) then
            add_to_notification_center(newest)
        end
    end)
end)

local function release_popup_box(notification, box)
    if active_animations[notification] then
        active_animations[notification]:stop()
        active_animations[notification] = nil
    end

    if box then
        pcall(function()
            box.visible = false
        end)
    end

    remove_from_popup_order(notification)
end

local function watch_notification_suspension(n)
    if suspension_handlers[n] then
        return
    end

    local handler = lifecycle.watch_suspension(n, function()
        add_to_notification_center(n)
        release_popup_box(n, active_boxes[n])
    end)
    suspension_handlers[n] = handler
end

screen.connect_signal("removed", function(s)
    for notification, box in pairs(active_boxes) do
        local ok, box_screen = pcall(function()
            return box.screen
        end)

        local is_valid_screen = false
        if ok and box_screen ~= nil then
            local valid_ok, valid = pcall(function()
                return box_screen.valid
            end)
            is_valid_screen = valid_ok and valid
        end

        if (not ok) or box_screen == nil or box_screen == s or (not is_valid_screen) then
            release_popup_box(notification, box)
        end
    end
end)

-- Defaults
naughty.config.defaults.ontop = true
naughty.config.defaults.icon_size = dpi(32)
-- timeout = 0 to prevent auto-destroy, we manage lifecycle via animation
naughty.config.defaults.timeout = 0
naughty.config.defaults.title = 'System Notification'
naughty.config.defaults.margin = dpi(16)
naughty.config.defaults.border_width = 0
naughty.config.defaults.position = 'top_left'
naughty.config.defaults.shape = function(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, dpi(6))
end

-- Apply theme variables
naughty.config.padding = dpi(8)
naughty.config.spacing = dpi(8)
naughty.config.icon_dirs = {
    '/usr/share/icons/Solarized-FLAT-Blue/',
    '/usr/share/icons/Solarized-Dark-Green-Numix/',
    '/usr/share/icons/hicolor/',
    '/usr/share/pixmaps/'
}

naughty.config.icon_formats = { 'svg', 'png', 'jpg', 'gif' }

-- Presets / rules

ruled.notification.connect_signal(
    'request::rules',
    function()
        -- Critical notifs
        ruled.notification.append_rule {
            rule       = { urgency = 'critical' },
            properties = {
                font             = beautiful.font_bold(12),
                bg               = beautiful.colors.red,
                fg               = beautiful.colors.red,
                margin           = dpi(16),
                position         = 'top_left'
            }
        }

        -- Normal notifs
        ruled.notification.append_rule {
            rule       = { urgency = 'normal' },
            properties = {
                font             = beautiful.font_regular(12),
                bg               = beautiful.bg_focus,
                fg               = beautiful.fg_normal,
                margin           = dpi(16),
                position         = 'top_left'
            }
        }

        -- Low notifs
        ruled.notification.append_rule {
            rule       = { urgency = 'low' },
            properties = {
                font             = beautiful.font_regular(12),
                bg               = beautiful.transparent,
                fg               = beautiful.fg_normal,
                margin           = dpi(16),
                position         = 'top_left'
            }
        }

        ruled.notification.append_rule {
            rule = {
                app_name = 'notify-send',
                title = 'OpenCode'
            },
            properties = {
                ignore = true
            }
        }
    end
)

-- Error handling
naughty.connect_signal(
    'request::display_error',
    function(message, startup)
        if displaying_error then
            io.stderr:write(tostring(message) .. '\n')
            return
        end

        displaying_error = true
        local ok, err = pcall(function()
            naughty.notification {
                urgency  = 'critical',
                title    = 'Oops, an error happened' .. (startup and ' during startup!' or '!'),
                message  = message,
                app_name = 'System Notification',
                icon     = beautiful.awesome_icon
            }
        end)
        displaying_error = false
        if not ok then
            io.stderr:write(tostring(err) .. '\n')
        end
    end
)

-- XDG icon lookup
naughty.connect_signal(
    "request::icon",
    function(n, _, hints)
        -- Handle cases where hints.app_icon is `nil`
        if hints.app_icon == nil then
            if n.app_name == nil then
                return
            else
                -- handle cases where n.app_name is not nil ex: slack
                hints.app_icon = n.app_name
            end
        end

        local path = menubar.utils.lookup_icon(hints.app_icon) or
            menubar.utils.lookup_icon(hints.app_icon:lower())

        if path then
            n.icon = path
        end
    end
)

--- Use XDG icon
naughty.connect_signal("request::action_icon", function(a, _, hints)
    a.icon = menubar.utils.lookup_icon(hints.id)
end)

-- Raise client, if destroyed by user
-- https://github.com/awesomeWM/awesome/issues/3182#issuecomment-1753211773
local function focus_new_urgent_client()
    local handler
    local timeout
    local function disconnect()
        client.disconnect_signal("property::urgent", handler)
        if timeout and timeout.started then
            timeout:stop()
        end
    end

    handler = function(c)
        if c and c.valid and c.urgent then
            c:jump_to()
            disconnect()
        end
    end
    client.connect_signal("property::urgent", handler)
    timeout = gears.timer.start_new(5, function()
        disconnect()
        return false
    end)
end

naughty.connect_signal("destroyed", function(n, reason)
    local suspension_handler = suspension_handlers[n]
    if suspension_handler then
        n:disconnect_signal('property::suspended', suspension_handler)
        suspension_handlers[n] = nil
    end
    remove_cards(notification_store:remove(n))
    gears.timer.delayed_call(function()
        active_boxes[n] = nil
    end)
    remove_from_popup_order(n)
    if active_animations[n] then
        active_animations[n]:stop()
        active_animations[n] = nil
    end

    if not n.clients then
        return
    end

    if reason == cst.notification_closed_reason.dismissed_by_user then
        focus_new_urgent_client()
    end
end)

-- Connect to naughty on display signal
naughty.connect_signal(
    'request::display',
    function(n)
        -- Animation duration for non-urgent notifications (5 seconds)
        -- Urgent notifications (from apps that set timeout=0) stay visible until dismissed
        local POPUP_DURATION = 5
        normalize_notification_urgency(n)
        local entry = notification_store:get(n) or track_notification(n)
        if not entry or next(entry.cards) then
            return
        end
        watch_notification_suspension(n)
        local is_urgent = n.urgency == 'critical'

        -- Actions Blueprint
        local actions_template = wibox.widget {
            notification = n,
            base_layout = wibox.widget {
                spacing = dpi(0),
                layout  = wibox.layout.flex.horizontal
            },
            widget_template = {
                {
                    {
                        {
                            {
                                id     = 'text_role',
                                font   = beautiful.font_regular(12),
                                widget = wibox.widget.textbox
                            },
                            widget = wibox.container.place
                        },
                        widget = clickable_container
                    },
                    bg            = beautiful.bg_normal,
                    shape         = gears.shape.rounded_rect,
                    forced_height = dpi(30),
                    widget        = wibox.container.background
                },
                margins = dpi(4),
                widget  = wibox.container.margin
            },
            style = { underline_normal = false, underline_selected = true },
            widget = naughty.list.actions
        }

        local timeout_arc = wibox.widget({
            widget = wibox.container.arcchart,
            forced_width = dpi(26),
            forced_height = dpi(26),
            max_value = 100,
            min_value = 0,
            value = 0,
            thickness = dpi(4),
            rounded_edge = true,
            bg = beautiful.notification_bg,
            colors = {
                {
                    type = "linear",
                    from = { 0, 0 },
                    to = { 400, 400 },
                    stops = {
                        { 0,   beautiful.accent },
                        { 0.2, beautiful.accent },
                        { 0.4, beautiful.accent },
                        { 0.6, beautiful.accent },
                        { 0.8, beautiful.accent },
                    },
                },
            },
            nil,
        })

        -- Notifbox Blueprint
        -- Store a strong reference to prevent GC (see active_boxes above)
        local notif_screen = preferred_notification_screen()
        if not notif_screen or not notif_screen.valid then
            return
        end
        local notif_w = notif_screen.geometry.width
        local notif_h = notif_screen.geometry.height
        local widget = naughty.layout.box {
            notification = n,
            type = 'notification',
            screen = notif_screen,
            shape = gears.shape.rectangle,
            widget_template = {
                {
                    {
                        {
                            {
                                {
                                    {
                                        {
                                            {
                                                {
                                                    {
                                                        layout = wibox.layout.align.horizontal,
                                                        {
                                                            text = n.app_name or 'System Notification',
                                                            font = beautiful.font_bold(12),
                                                            align = 'center',
                                                            valign = 'center',
                                                            widget = wibox.widget.textbox
                                                        },
                                                        nil,
                                                        timeout_arc,

                                                    },
                                                    margins = beautiful.notification_margin,
                                                    widget  = wibox.container.margin,
                                                },
                                                bg     = beautiful.background:sub(1, 7),
                                                widget = wibox.container.background,
                                            },
                                            {
                                                forced_height = dpi(2),
                                                color         = beautiful.accent,
                                                orientation   = 'horizontal',
                                                widget        = wibox.widget.separator,
                                            },
                                            {
                                                {
                                                    {
                                                        resize_strategy = 'center',
                                                        widget = naughty.widget.icon,
                                                    },
                                                    margins = beautiful.notification_margin,
                                                    widget  = wibox.container.margin,
                                                },
                                                {
                                                    {
                                                        layout = wibox.layout.align.vertical,
                                                        expand = 'none',
                                                        nil,
                                                        {
                                                            {
                                                                align = 'left',
                                                                widget = naughty.widget.title
                                                            },
                                                            {
                                                                align = 'left',
                                                                widget = naughty.widget.message,
                                                            },
                                                            layout = wibox.layout.fixed.vertical
                                                        },
                                                        nil
                                                    },
                                                    margins = beautiful.notification_margin,
                                                    widget  = wibox.container.margin,
                                                },
                                                layout = wibox.layout.fixed.horizontal,
                                            },
                                            fill_space = true,
                                            spacing    = dpi(0),
                                            layout     = wibox.layout.fixed.vertical,
                                        },
                                        -- Margin between the fake background
                                        -- Set to 0 to preserve the 'titlebar' effect
                                        margins = dpi(0),
                                        widget  = wibox.container.margin,
                                    },
                                    bg     = beautiful.background_light,
                                    widget = wibox.container.background,
                                },
                                -- Actions
                                actions_template,
                                spacing = dpi(4),
                                layout  = wibox.layout.fixed.vertical,
                            },
                            bg     = beautiful.transparent,
                            id     = 'background_role',
                            widget = naughty.container.background,
                        },
                        strategy = 'min',
                        width    = notif_w / 6,
                        widget   = wibox.container.constraint,
                    },
                    strategy = 'max',
                    height   = notif_h / 4,
                    width    = notif_w / 6,
                    widget   = wibox.container.constraint
                },
                bg = beautiful.background,
                shape = gears.shape.rounded_rect,
                border_width = dpi(2),
                border_color = beautiful.accent,
                border_strategy = 'inner',
                widget = wibox.container.background
            }
        }

        -- Hold a strong reference so the wibox is not garbage-collected
        -- while naughty's internal weak-value table still tracks it.
        active_boxes[n] = widget
        popup_order[#popup_order + 1] = n

        if #popup_order > MAX_VISIBLE_POPUPS then
            local oldest = popup_order[1]
            add_to_notification_center(oldest)
            release_popup_box(oldest, active_boxes[oldest])
        end

        local anim
        if not is_urgent then
            anim = animation:new({
                duration = POPUP_DURATION,
                target = 100,
                easing = animation.easing.linear,
                reset_on_stop = false,
                update = function(_, pos)
                    timeout_arc.value = pos
                end,
            })
            active_animations[n] = anim

            anim:connect_signal("ended", function()
                -- Instead of destroying the notification (which closes D-Bus),
                -- move it to the info center while keeping it alive
                add_to_notification_center(n)
                release_popup_box(n, widget)
            end)

            widget:connect_signal("mouse::enter", function()
                anim:stop()
            end)

            widget:connect_signal("mouse::leave", function()
                anim:start()
            end)

            anim:start()
        else
            timeout_arc.value = 100
        end

        if n.suspended then
            add_to_notification_center(n)
            release_popup_box(n, widget)
        end
    end
)

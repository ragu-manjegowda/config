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
                position         = 'top_left',
                implicit_timeout = 0
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
                position         = 'top_left',
                -- timeout = 0 to prevent auto-destroy,
                -- we manage lifecycle ourselves
                implicit_timeout = 0
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
                position         = 'top_left',
                -- timeout = 0 to prevent auto-destroy,
                -- we manage lifecycle ourselves
                implicit_timeout = 0
            }
        }

        ruled.notification.append_rule {
            rule       = { app_name = 'Slack' },
            properties = {
                implicit_timeout = 0
            }
        }

        -- ruled.notification.append_rule {
        --     rule       = { app_name = 'Email' },
        --     properties = {
        --         ignore    = true
        --     }
        -- }
    end
)

-- Error handling
naughty.connect_signal(
    'request::display_error',
    function(message, startup)
        naughty.notification {
            urgency  = 'critical',
            title    = 'Oops, an error happened' .. (startup and ' during startup!' or '!'),
            message  = message,
            app_name = 'System Notification',
            icon     = beautiful.awesome_icon
        }
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
naughty.connect_signal("destroyed", function(n, reason)
    if not n.clients then
        return
    end

    if reason == cst.notification_closed_reason.dismissed_by_user then
        -- If we clicked on a notification, we get a new urgent client to jump to
        client.connect_signal("property::urgent", function(c)
            -- We don't use notification_client because it's not reliable
            -- (Ex: If we have two different instances of chrome)
            -- cf: https://awesomewm.org/apidoc/core_components/naughty.notification.html#clients
            -- So we just check if the client name of our notification is
            -- the same as the last urgent client and jump to this one.
            for _, notification_client in ipairs(n.clients) do
                -- For whatever reason, `c` can be nil
                if c == nil then
                    return
                end

                if c.name == notification_client.name then
                    c:jump_to()
                end
            end
        end)
    end
end)

-- Connect to naughty on display signal
naughty.connect_signal(
    'request::display',
    function(n)
        -- Animation duration for non-urgent notifications (5 seconds)
        -- Urgent notifications (from apps that set timeout=0) stay visible until dismissed
        local POPUP_DURATION = 5
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
        local widget = naughty.layout.box {
            notification = n,
            type = 'notification',
            screen = awful.screen.preferred(),
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
                                                            markup = n.app_name or 'System Notification',
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
                                                bg     = beautiful.bg_focus,
                                                widget = wibox.container.background,
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
                                            spacing    = beautiful.notification_margin,
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
                        width    = awful.screen.preferred().geometry.width / 6,
                        widget   = wibox.container.constraint,
                    },
                    strategy = 'max',
                    height   = awful.screen.preferred().geometry.height / 4,
                    width    = awful.screen.preferred().geometry.width / 6,
                    widget   = wibox.container.constraint
                },
                bg = beautiful.background,
                shape = gears.shape.rounded_rect,
                widget = wibox.container.background
            }
        }

        -- Animation for popup display duration
        local anim = animation:new({
            duration = POPUP_DURATION,
            target = 100,
            easing = animation.easing.linear,
            reset_on_stop = false,
            loop = is_urgent, -- urgent notifications loop until dismissed
            update = function(_, pos)
                timeout_arc.value = pos
            end,
        })

        -- Only handle timeout for non-urgent notifications
        -- Urgent notifications (timeout = 0) stay visible until user dismisses
        if not is_urgent then
            anim:connect_signal("ended", function()
                -- Instead of destroying the notification (which closes D-Bus),
                -- move it to the info center while keeping it alive
                local notif_core = require('widget.notif-center.build-notifbox')
                if notif_core.add_notification then
                    notif_core.add_notification(n)
                end
                -- Just hide the popup widget
                widget.visible = false
            end)
        end

        widget:connect_signal("mouse::enter", function()
            anim:stop()
        end)

        widget:connect_signal("mouse::leave", function()
            anim:start()
        end)

        anim:start()

        -- Hide popups if dont_disturb_state mode is on
        -- Or if the info_center is visible
        local focused = awful.screen.focused()
        if _G.dont_disturb_state or (focused.info_center and focused.info_center.visible) then
            -- Add this notification to notification center while keeping it alive
            local notif_core = require('widget.notif-center.build-notifbox')
            if notif_core.add_notification then
                notif_core.add_notification(n)
            end
            -- Just hide the popup, don't destroy the notification
            widget.visible = false
            anim:stop()
        end
    end
)

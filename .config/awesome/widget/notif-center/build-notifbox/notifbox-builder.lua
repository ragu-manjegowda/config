local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')
local beautiful = require('beautiful')

local dpi = beautiful.xresources.apply_dpi

local builder = require('widget.notif-center.build-notifbox.notifbox-ui-elements')
local notifbox_core = require('widget.notif-center.build-notifbox')

local notifbox_layout = notifbox_core.notifbox_layout
local reset_notifbox_layout = notifbox_core.reset_notifbox_layout

local age_entries = setmetatable({}, { __mode = 'k' })
local age_timer

local function update_age(entry)
    local age = os.time() - entry.created_at

    if age < 60 then
        entry.widget:set_markup('now')
    elseif age < 3600 then
        entry.widget:set_markup(math.floor(age / 60) .. 'm ago')
    elseif age < 86400 then
        entry.widget:set_markup(os.date('%I:%M %p', entry.created_at))
    else
        entry.widget:set_markup(os.date('%b %d, %I:%M %p', entry.created_at))
    end
end

local function update_ages()
    local has_entries = false

    for _, entry in pairs(age_entries) do
        has_entries = true
        update_age(entry)
    end

    if not has_entries then
        age_timer:stop()
    end
end

local function register_age(notifbox, widget, created_at)
    age_entries[notifbox] = { widget = widget, created_at = created_at }
    update_age(age_entries[notifbox])

    if not age_timer then
        age_timer = gears.timer {
            timeout = 60,
            callback = update_ages,
        }
    end

    if not age_timer.started then
        age_timer:start()
    end
end

local notifbox_box = function(notif, icon, title, message, app, _)
    local created_at = os.time()

    local notifbox_timepop = wibox.widget {
        id = 'time_pop',
        markup = nil,
        font = beautiful.font_regular(10),
        align = 'left',
        valign = 'center',
        visible = true,
        widget = wibox.widget.textbox
    }

    local notifbox_dismiss = builder.notifbox_dismiss()

    local notifbox_content = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        {
            expand = 'none',
            layout = wibox.layout.align.horizontal,
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(5),
                builder.notifbox_icon(icon),
                builder.notifbox_appname(app),
            },
            nil,
            {
                notifbox_timepop,
                notifbox_dismiss,
                layout = wibox.layout.fixed.horizontal
            }
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            {
                builder.notifbox_title(title),
                builder.notifbox_message(message),
                layout = wibox.layout.fixed.vertical
            },
            builder.notifbox_actions(notif),
        },
    }

    -- Inner template with background matching stocks
    local notifbox_template = wibox.widget {
        id = 'notifbox_template',
        {
            notifbox_content,
            margins = dpi(10),
            widget = wibox.container.margin
        },
        bg = beautiful.background,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
        end,
        widget = wibox.container.background,
    }

    -- Put the generated template to a container with accent-colored left border
    local notifbox = wibox.widget {
        {
            -- Accent left border
            {
                forced_width = dpi(4),
                bg = beautiful.accent,
                widget = wibox.container.background,
            },
            -- Content area with inner background
            {
                notifbox_template,
                left = dpi(8),
                right = dpi(8),
                top = 0,
                bottom = 0,
                widget = wibox.container.margin,
            },
            layout = wibox.layout.align.horizontal,
        },
        bg = beautiful.groups_bg,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
        end,
        widget = wibox.container.background
    }
    local hints = notif._private.freedesktop_hints
    notifbox._retention_priority = tonumber(notif._private.retention_priority or
        (hints and hints['x-awesome-retention-priority'])) or
        (notif.urgency == 'critical' and 2 or 0)

    register_age(notifbox, notifbox_timepop, created_at)
    notifbox:connect_signal('widget::dismiss', function()
        if notif then
            naughty.destroy(notif, naughty.notification_closed_reason.expired)
            notif = nil
        end
    end)
    notifbox:connect_signal('widget::removed', function()
        age_entries[notifbox] = nil
        if age_timer and not next(age_entries) then
            age_timer:stop()
        end
    end)

    local notifbox_delete = function()
        notifbox:emit_signal('widget::removed')
        notifbox_layout:remove_widgets(notifbox, true)
    end

    -- Track if mouse is hovering over dismiss button
    local dismiss_hovered = false

    notifbox_dismiss:connect_signal('mouse::enter', function()
        dismiss_hovered = true
    end)

    notifbox_dismiss:connect_signal('mouse::leave', function()
        dismiss_hovered = false
    end)

    -- Add click handler to dismiss button (delete only, keep notification center open)
    notifbox_dismiss:buttons(
        awful.util.table.join(
            awful.button(
                {},
                1,
                function()
                    -- Just delete, don't focus or close notification center
                    notifbox:emit_signal('widget::dismiss')
                    if #notifbox_layout.children == 1 then
                        notifbox:emit_signal('widget::removed')
                        reset_notifbox_layout()
                    else
                        notifbox_delete()
                        if _G.update_notif_count then
                            _G.update_notif_count(#notifbox_layout.children)
                        end
                    end
                end
            )
        )
    )

    -- Invoke the notification's default action via D-Bus
    -- This tells the app to open the relevant content (tab, conversation, etc.)
    local invoke_default_action = function()
        if notif and notif._private and notif._private.action_cb then
            -- Invoke the "default" action - this sends ActionInvoked D-Bus signal
            notif._private.action_cb("default")
            -- Then destroy the notification properly
            naughty.destroy(notif, naughty.notification_closed_reason.dismissed_by_user)
            notif = nil
            return true
        end
        return false
    end

    -- Focus client by various methods
    local focus_client = function()
        -- First, try to invoke the default D-Bus action
        if invoke_default_action() then
            return true
        end

        -- Fallback: just destroy the notification if it exists
        if notif then
            naughty.destroy(notif, naughty.notification_closed_reason.dismissed_by_user)
            notif = nil
        end

        -- Fallback: try to find and focus the client by app name
        if app and app ~= '' then
            for _, c in ipairs(client.get()) do
                if c.class and c.class:lower():find(app:lower()) then
                    c:jump_to()
                    return true
                end
            end
        end

        return false
    end

    -- LMB: Focus client and delete notification
    -- RMB: Just delete notification without focusing
    notifbox:buttons(
        awful.util.table.join(
            awful.button(
                {},
                1, -- Left click: focus client then delete
                function()
                    -- Skip if hovering over dismiss button (it has its own handler)
                    if dismiss_hovered then
                        return
                    end

                    -- Try to focus the associated client
                    focus_client()

                    -- Close info center if open
                    local focused = awful.screen.focused()
                    if focused and focused.valid and focused.info_center and focused.info_center.visible then
                        focused.info_center:toggle()
                    end

                    -- Delete the notification
                    if #notifbox_layout.children == 1 then
                        notifbox:emit_signal('widget::removed')
                        reset_notifbox_layout()
                    else
                        notifbox_delete()
                        if _G.update_notif_count then
                            _G.update_notif_count(#notifbox_layout.children)
                        end
                    end
                end
            ),
            awful.button(
                {},
                3, -- Right click: just delete without focusing
                function()
                    notifbox:emit_signal('widget::dismiss')
                    if #notifbox_layout.children == 1 then
                        notifbox:emit_signal('widget::removed')
                        reset_notifbox_layout()
                    else
                        notifbox_delete()
                        if _G.update_notif_count then
                            _G.update_notif_count(#notifbox_layout.children)
                        end
                    end
                end
            )
        )
    )

    -- Add hover, and mouse leave events
    notifbox_template:connect_signal(
        'mouse::enter',
        function()
            notifbox.bg = beautiful.groups_bg
            notifbox_timepop.visible = false
            notifbox_dismiss.visible = true
        end
    )

    notifbox_template:connect_signal(
        'mouse::leave',
        function()
            notifbox.bg = beautiful.tranparent
            notifbox_timepop.visible = true
            notifbox_dismiss.visible = false
        end
    )

    return notifbox
end


return notifbox_box

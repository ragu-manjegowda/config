local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi

-- Scroll state
local SCROLL_STEP = dpi(60)
local MAX_NOTIFS_VISIBLE = 2

local notif_center = function(s)
    local notif_manager = require('widget.notif-center.build-notifbox')
    local notif_core = notif_manager.new_view()
    s.clear_all = require('widget.notif-center.clear-all')()

    local notif_header = wibox.widget {
        text   = 'Notification Center',
        font   = beautiful.font_bold(14),
        align  = 'left',
        valign = 'center',
        widget = wibox.widget.textbox
    }

    local notif_count_widget = wibox.widget {
        {
            {
                id = 'count_text',
                text = '0',
                font = beautiful.font_bold(10),
                align = 'center',
                valign = 'center',
                widget = wibox.widget.textbox
            },
            left = dpi(6),
            right = dpi(6),
            top = dpi(2),
            bottom = dpi(2),
            widget = wibox.container.margin,
        },
        bg = beautiful.accent or beautiful.bg_focus,
        fg = beautiful.fg_focus or beautiful.fg_normal,
        shape = gears.shape.rounded_bar,
        visible = false,
        widget = wibox.container.background,
    }

    local function update_notif_count(count)
        local count_text = notif_count_widget:get_children_by_id('count_text')[1]
        count_text.text = tostring(count)
        notif_count_widget.visible = count > 0
    end

    s.notifbox_layout = notif_core.notifbox_layout
    local fit_context = {
        screen = s,
        dpi = beautiful.xresources.get_dpi(s),
    }
    local content_width = s.geometry.width / 6 - dpi(20)
    local screen_active = true

    local function is_screen_active()
        if not screen_active then
            return false
        end

        local ok, valid = pcall(function()
            return s.valid
        end)

        return ok and valid
    end

    -- Scroll state (per screen)
    local scroll_offset = 0
    local max_scroll = 0
    local content_height = 0
    local visible_height = 0

    -- Scrollbar thumb widget
    local scrollbar_thumb = wibox.widget {
        forced_width = dpi(4),
        forced_height = dpi(30),
        bg = beautiful.fg_normal .. 'AA',
        shape = gears.shape.rounded_bar,
        widget = wibox.container.background,
    }

    -- Scrollbar container
    local scrollbar_container = wibox.widget {
        scrollbar_thumb,
        top = 0,
        widget = wibox.container.margin,
    }

    local scrollbar_track = wibox.widget {
        scrollbar_container,
        forced_width = dpi(6),
        bg = beautiful.bg_focus .. '40',
        shape = gears.shape.rounded_bar,
        visible = false,
        widget = wibox.container.background,
    }

    -- Scroll content container with margin for offset
    local scroll_content = wibox.widget {
        s.notifbox_layout,
        top = 0,
        widget = wibox.container.margin,
    }

    -- Constraint widget for dynamic height
    local scroll_clip = wibox.widget {
        {
            {
                scroll_content,
                layout = wibox.layout.fixed.vertical,
            },
            bg = beautiful.transparent or "#00000000",
            shape = function(cr, w, h)
                gears.shape.rectangle(cr, w, h)
            end,
            widget = wibox.container.background,
        },
        strategy = 'max',
        height = 0,
        widget = wibox.container.constraint,
    }

    -- Function to update scrollbar and height
    local function update_scrollbar()
        if not is_screen_active() or not s.notifbox_layout then return end
        local children = s.notifbox_layout.children
        local spacing = s.notifbox_layout.spacing or 0
        content_height = 0
        visible_height = 0
        for index, child in ipairs(children) do
            local _, child_height = wibox.widget.base.fit_widget(
                s.notifbox_layout,
                fit_context,
                child,
                content_width,
                s.geometry.height
            )
            if index > 1 then
                content_height = content_height + spacing
                if index <= MAX_NOTIFS_VISIBLE then
                    visible_height = visible_height + spacing
                end
            end
            content_height = content_height + child_height
            if index <= MAX_NOTIFS_VISIBLE then
                visible_height = visible_height + child_height
            end
        end
        scroll_clip.height = visible_height
        scrollbar_track.forced_height = visible_height

        max_scroll = math.max(0, content_height - visible_height)
        scroll_offset = math.max(0, math.min(scroll_offset, max_scroll))

        if max_scroll > 0 then
            scrollbar_track.visible = true
            local thumb_ratio = visible_height / content_height
            local thumb_height = math.max(dpi(20), math.min(visible_height - dpi(10), visible_height * thumb_ratio))
            scrollbar_thumb.forced_height = thumb_height

            local scroll_ratio = max_scroll > 0 and (scroll_offset / max_scroll) or 0
            local track_space = visible_height - thumb_height
            scrollbar_container.top = track_space * scroll_ratio
        else
            scrollbar_track.visible = false
            scroll_offset = 0
        end

        scroll_content.top = -scroll_offset
    end

    -- Scroll function
    local function do_scroll(direction)
        local old_offset = scroll_offset
        if direction == 'up' then
            scroll_offset = math.max(0, scroll_offset - SCROLL_STEP)
        elseif direction == 'down' then
            scroll_offset = math.min(max_scroll, scroll_offset + SCROLL_STEP)
        end
        if old_offset ~= scroll_offset then
            update_scrollbar()
        end
    end

    -- Layout change handler
    local function on_layout_changed()
        if not is_screen_active() or not s.notifbox_layout then return end
        local child_count = #s.notifbox_layout.children
        if child_count == 1 and notif_core.remove_notifbox_empty then
            update_notif_count(0)
        else
            update_notif_count(child_count)
        end
        gears.timer.delayed_call(update_scrollbar)
    end

    s.notifbox_layout:connect_signal('widget::layout_changed', on_layout_changed)

    screen.connect_signal('removed', function(removed)
        if removed ~= s then
            return
        end

        screen_active = false
        notif_manager.remove_view(notif_core)
        notif_core.notifbox_layout:disconnect_signal('widget::layout_changed', on_layout_changed)
    end)

    -- Stack scrollbar on top of clipped content
    local scroll_area = wibox.widget {
        scroll_clip,
        {
            nil,
            nil,
            {
                scrollbar_track,
                right = dpi(2),
                widget = wibox.container.margin,
            },
            layout = wibox.layout.align.horizontal,
        },
        layout = wibox.layout.stack,
    }

    scroll_area:buttons(gears.table.join(
        awful.button({}, 4, function() do_scroll('up') end),
        awful.button({}, 5, function() do_scroll('down') end)
    ))

    gears.timer.delayed_call(on_layout_changed)

    -- Main widget with separate header and scroll areas
    return wibox.widget {
        {
            {
                -- Header row (not scrollable)
                {
                    layout = wibox.layout.align.horizontal,
                    expand = 'none',
                    {
                        notif_header,
                        {
                            notif_count_widget,
                            left = dpi(8),
                            widget = wibox.container.margin,
                        },
                        layout = wibox.layout.fixed.horizontal,
                    },
                    nil,
                    s.clear_all
                },
                -- Spacing between header and scroll area
                {
                    forced_height = dpi(10),
                    widget = wibox.container.background,
                },
                -- Scrollable notification area (separate from header)
                scroll_area,
                layout = wibox.layout.fixed.vertical,
            },
            margins = dpi(10),
            widget = wibox.container.margin
        },
        bg = beautiful.groups_bg,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
        widget = wibox.container.background
    }
end

return notif_center

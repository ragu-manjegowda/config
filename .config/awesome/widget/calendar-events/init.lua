local awful = require('awful')
local gears = require('gears')
local wibox = require('wibox')
local beautiful = require('beautiful')
local json = require('library.json')
local clickable_container = require('widget.clickable-container')

local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local refresh_icon_path = config_dir .. 'widget/weather/icons/refresh.svg'
local config = require('configuration.config')

local calendar_cfg = config.widget.calendar_events or {}
local fetch_script = calendar_cfg.script or (config_dir .. 'utilities/outlook-calendar')
local max_items = tonumber(calendar_cfg.max_items) or 0
local show_cancelled = calendar_cfg.show_cancelled or false
local window_days = calendar_cfg.window_days or 2

local EVENT_HEIGHT = dpi(68)
local SUB_EVENT_HEIGHT = dpi(54)
local MAX_EVENTS_VISIBLE = 3
local MAX_HEIGHT = EVENT_HEIGHT * MAX_EVENTS_VISIBLE + dpi(5)
local EVENT_SPACING = dpi(5)
local SCROLL_STEP = dpi(40)

local header_widget = wibox.widget {
    text = 'Calendar',
    font = beautiful.font_bold(14),
    align = 'left',
    valign = 'center',
    widget = wibox.widget.textbox,
}

local count_text = wibox.widget {
    text = '0',
    font = beautiful.font_bold(10),
    align = 'center',
    valign = 'center',
    widget = wibox.widget.textbox,
}

local count_badge = wibox.widget {
    {
        count_text,
        left = dpi(6),
        right = dpi(6),
        widget = wibox.container.margin,
    },
    bg = beautiful.accent,
    fg = beautiful.fg_focus,
    shape = gears.shape.rounded_bar,
    visible = false,
    widget = wibox.container.background,
}

local refresh_button = wibox.widget {
    {
        {
            image = refresh_icon_path,
            resize = true,
            forced_height = dpi(14),
            forced_width = dpi(14),
            widget = wibox.widget.imagebox,
        },
        margins = dpi(4),
        widget = wibox.container.margin,
    },
    bg = beautiful.accent,
    shape = gears.shape.circle,
    widget = clickable_container,
}

local header_time = wibox.widget {
    markup = '--:--',
    font = beautiful.font_regular(10),
    align = 'center',
    valign = 'center',
    widget = wibox.widget.textbox,
}

local event_list_layout = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = EVENT_SPACING,
}

local scroll_offset = 0
local max_scroll = 0
local content_height = 0
local visible_height = MAX_HEIGHT
local last_visible_events = {}
local last_visible_limit = 0
local scroll_timer = nil
local update_time
local last_payload = nil
local expanded_group_key = nil
local row_anchor_offsets = {}

local scrollbar_thumb = wibox.widget {
    forced_width = dpi(4),
    forced_height = dpi(30),
    bg = beautiful.fg_normal .. 'AA',
    shape = gears.shape.rounded_bar,
    widget = wibox.container.background,
}

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

local function date_to_timestamp(date_text, time_text)
    if not date_text or date_text == '' then
        return nil
    end

    local year, month, day = date_text:match('^(%d+)%-(%d+)%-(%d+)$')
    if not year then
        return nil
    end

    local hour = 0
    local min = 0
    local sec = 0
    if time_text and time_text ~= '' then
        local h, m, s = time_text:match('^(%d+):(%d+):?(%d*)$')
        if h and m then
            hour = tonumber(h) or 0
            min = tonumber(m) or 0
            if s and s ~= '' then
                sec = tonumber(s) or 0
            end
        end
    end

    return os.time {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = hour,
        min = min,
        sec = sec,
    }
end

local function event_date_text(event)
    return (event.start or ''):match('^(%d%d%d%d%-%d%d%-%d%d)')
end

local function event_end_timestamp(event)
    local end_date, end_time = (event['end'] or ''):match('^(%d%d%d%d%-%d%d%-%d%d)T(%d%d:%d%d:%d%d)')
    if end_date then
        return date_to_timestamp(end_date, end_time)
    end

    local start_date, start_time = (event.start or ''):match('^(%d%d%d%d%-%d%d%-%d%d)T(%d%d:%d%d:%d%d)')
    if start_date then
        return date_to_timestamp(start_date, start_time)
    end

    return nil
end

local function event_start_timestamp(event)
    local start_date, start_time = (event.start or ''):match('^(%d%d%d%d%-%d%d%-%d%d)T(%d%d:%d%d:%d%d)')
    if start_date then
        return date_to_timestamp(start_date, start_time)
    end

    return nil
end

local function event_day_label(event)
    local event_date = event_date_text(event)
    if not event_date then
        return 'Upcoming'
    end

    local today = os.date('%Y-%m-%d')
    if event_date == today then
        return 'Today'
    end

    local tomorrow = os.date('%Y-%m-%d', os.time() + 24 * 60 * 60)
    if event_date == tomorrow then
        return 'Tomorrow'
    end

    local ts = date_to_timestamp(event_date, '00:00:00')
    if ts then
        return os.date('%a', ts)
    end

    return event_date
end

local function is_missed_today(event)
    if event.is_all_day then
        return false
    end

    local event_date = event_date_text(event)
    if event_date ~= os.date('%Y-%m-%d') then
        return false
    end

    local end_ts = event_end_timestamp(event)
    if not end_ts then
        return false
    end

    return end_ts < os.time()
end

local function event_time_label(event)
    local day_label = event_day_label(event)
    local time_label = event.is_all_day and 'All Day' or ((event.start_label or '--:--') .. ' - ' .. (event.end_label or '--:--'))
    local details = day_label .. ' | ' .. time_label
    if is_missed_today(event) then
        details = details .. ' | Missed'
    end
    return details
end

local function event_details_text(event)
    local details = event_time_label(event)
    if event.location and event.location ~= '' then
        details = details .. ' | ' .. event.location
    end
    return details
end

local function build_event_row(title_text, details_text, options)
    options = options or {}

    local title_widget = wibox.widget {
        markup = '<b>' .. gears.string.xml_escape(title_text or '(No title)') .. '</b>',
        font = beautiful.font_regular(10),
        widget = wibox.widget.textbox,
    }

    local details_widget = wibox.widget {
        markup = '<span foreground="#AAAAAA">' .. gears.string.xml_escape(details_text or '') .. '</span>',
        font = beautiful.font_regular(9),
        widget = wibox.widget.textbox,
    }

    local title_row = wibox.widget {
        title_widget,
        nil,
        options.badge or nil,
        layout = wibox.layout.align.horizontal,
    }

    local card_inner = wibox.widget {
        {
            {
                title_row,
                details_widget,
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(2),
            },
            margins = dpi(10),
            widget = wibox.container.margin,
        },
        bg = beautiful.background,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
        widget = wibox.container.background,
    }

    return wibox.widget {
        {
            {
                forced_width = dpi(4),
                bg = options.border_color or beautiful.accent,
                widget = wibox.container.background,
            },
            {
                card_inner,
                left = dpi(8),
                right = dpi(8),
                widget = wibox.container.margin,
            },
            layout = wibox.layout.align.horizontal,
        },
        bg = beautiful.groups_bg,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
        forced_height = options.height or EVENT_HEIGHT,
        widget = wibox.container.background,
    }
end

local function event_row(event, concurrent_count)
    local badge = nil
    if concurrent_count and concurrent_count > 1 then
        badge = wibox.widget {
            {
                {
                    text = string.format('Concurrent: %d', concurrent_count),
                    font = beautiful.font_regular(8),
                    align = 'center',
                    valign = 'center',
                    widget = wibox.widget.textbox,
                },
                left = dpi(6),
                right = dpi(6),
                top = dpi(2),
                bottom = dpi(2),
                widget = wibox.container.margin,
            },
            bg = beautiful.bg_focus,
            shape = gears.shape.rounded_bar,
            widget = wibox.container.background,
        }
    end

    return build_event_row(event.subject or '(No title)', event_details_text(event), {
        badge = badge,
        height = EVENT_HEIGHT,
        border_color = beautiful.accent,
    })
end

local function concurrent_detail_row(event, idx)
    local title = string.format('%d. %s', idx, event.subject or '(No title)')
    local details = event_details_text(event)
    if event.organizer and event.organizer ~= '' then
        details = details .. ' | ' .. event.organizer
    end

    return build_event_row(title, details, {
        height = SUB_EVENT_HEIGHT,
        border_color = beautiful.fg_normal .. '88',
    })
end

local function event_group_key(event)
    if event.is_all_day then
        return 'allday|' .. (event.start or event.start_label or event.subject or '')
    end
    return 'timed|' .. (event.start or ((event_date_text(event) or '') .. '|' .. (event.start_label or '')))
end

local function group_visible_events(visible, limit)
    local groups = {}
    local group_lookup = {}

    for i = 1, limit do
        local event = visible[i]
        local key = event_group_key(event)
        local group = group_lookup[key]
        if not group then
            group = {
                key = key,
                first_index = i,
                events = {},
            }
            group_lookup[key] = group
            table.insert(groups, group)
        end

        table.insert(group.events, event)
    end

    return groups
end

local function status_row(message)
    return wibox.widget {
        {
            {
                text = message,
                font = beautiful.font_regular(10),
                align = 'center',
                valign = 'center',
                widget = wibox.widget.textbox,
            },
            margins = dpi(12),
            widget = wibox.container.margin,
        },
        bg = beautiful.background,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
        forced_height = EVENT_HEIGHT,
        widget = wibox.container.background,
    }
end

local function clear_rows()
    for i = #event_list_layout.children, 1, -1 do
        event_list_layout:remove(i)
    end
    row_anchor_offsets = {}
end

local function update_count(count)
    count_text.text = tostring(count)
    count_badge.visible = count > 0
end

local scroll_content = wibox.widget {
    event_list_layout,
    top = 0,
    widget = wibox.container.margin,
}

local scroll_clip

local function update_scrollbar()
    local child_count = #event_list_layout.children
    content_height = 0
    for i, child in ipairs(event_list_layout.children) do
        content_height = content_height + (child.forced_height or EVENT_HEIGHT)
        if i < child_count then
            content_height = content_height + EVENT_SPACING
        end
    end

    visible_height = math.min(content_height, MAX_HEIGHT)
    scroll_clip.height = visible_height
    scrollbar_track.forced_height = visible_height

    max_scroll = math.max(0, content_height - MAX_HEIGHT)
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

local function scroll_to_current_event(events, limit)
    if not events or #events == 0 or limit <= 0 then
        scroll_offset = 0
        update_scrollbar()
        return
    end

    local now_ts = os.time()
    local today = os.date('%Y-%m-%d')
    local target_index = nil

    for i = 1, limit do
        local event = events[i]
        if not event.is_all_day then
            local start_ts = event_start_timestamp(event)
            local end_ts = event_end_timestamp(event)
            if start_ts and end_ts and start_ts <= now_ts and end_ts >= now_ts then
                target_index = i
                break
            end
        end
    end

    if not target_index then
        for i = 1, limit do
            local event = events[i]
            if not event.is_all_day then
                local start_ts = event_start_timestamp(event)
                if start_ts and start_ts >= now_ts then
                    target_index = i
                    break
                end
            end
        end
    end

    if not target_index then
        for i = 1, limit do
            local event = events[i]
            if event.is_all_day and event_date_text(event) == today then
                target_index = i
                break
            end
        end
    end

    if not target_index then
        for i = 1, limit do
            local event = events[i]
            local event_date = event_date_text(event)
            if event_date and event_date > today then
                target_index = i
                break
            end
        end
    end

    if not target_index then
        target_index = limit
    end

    local anchor_offset = row_anchor_offsets[target_index]
    if anchor_offset then
        scroll_offset = math.max(0, anchor_offset - (EVENT_HEIGHT + EVENT_SPACING))
    else
        local top_index = math.max(1, target_index - 1)
        local row_height = EVENT_HEIGHT + EVENT_SPACING
        scroll_offset = (top_index - 1) * row_height
    end
    update_scrollbar()
end

local function clear_scroll_timer()
    if scroll_timer then
        scroll_timer:stop()
        scroll_timer = nil
    end
end

local function schedule_scroll_timer(events, limit)
    clear_scroll_timer()

    local now_ts = os.time()
    local next_ts = nil

    for i = 1, limit do
        local event = events[i]
        local end_ts = event_end_timestamp(event)
        local start_ts = event_start_timestamp(event)

        if start_ts and start_ts > now_ts and (not next_ts or start_ts < next_ts) then
            next_ts = start_ts
        end

        if end_ts and end_ts > now_ts then
            local after_end = end_ts + 1
            if not next_ts or after_end < next_ts then
                next_ts = after_end
            end
        end
    end

    local tomorrow_midnight = os.time {
        year = tonumber(os.date('%Y')),
        month = tonumber(os.date('%m')),
        day = tonumber(os.date('%d')) + 1,
        hour = 0,
        min = 0,
        sec = 1,
    }
    if not next_ts or tomorrow_midnight < next_ts then
        next_ts = tomorrow_midnight
    end

    local delay = math.max(1, next_ts - now_ts)
    scroll_timer = gears.timer.start_new(delay, function()
        scroll_to_current_event(last_visible_events, last_visible_limit)
        update_time()
        schedule_scroll_timer(last_visible_events, last_visible_limit)
        return false
    end)
end

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

local function render_payload(payload)
    last_payload = payload
    clear_rows()

    if not payload or payload.ok ~= true then
        local message = 'Calendar unavailable'
        if payload and payload.error and payload.error ~= '' then
            message = payload.error
        end
        update_count(0)
        event_list_layout:add(status_row(message))
        last_visible_events = {}
        last_visible_limit = 0
        scroll_offset = 0
        update_scrollbar()
        schedule_scroll_timer(last_visible_events, last_visible_limit)
        return
    end

    local events = payload.events or {}
    local visible = {}

    for _, event in ipairs(events) do
        if show_cancelled or not event.is_cancelled then
            table.insert(visible, event)
        end
    end

    update_count(#visible)

    if #visible == 0 then
        event_list_layout:add(status_row('No events today'))
        last_visible_events = {}
        last_visible_limit = 0
        scroll_offset = 0
        update_scrollbar()
        schedule_scroll_timer(last_visible_events, last_visible_limit)
        return
    end

    local limit = #visible
    if max_items > 0 then
        limit = math.min(#visible, max_items)
    end

    local groups = group_visible_events(visible, limit)
    local y_offset = 0

    for _, group in ipairs(groups) do
        local primary = group.events[1]
        row_anchor_offsets[group.first_index] = y_offset

        local row = event_row(primary, #group.events)
        if #group.events > 1 then
            row:buttons(
                gears.table.join(
                    awful.button({}, 1, nil, function()
                        if expanded_group_key == group.key then
                            expanded_group_key = nil
                        else
                            expanded_group_key = group.key
                        end
                        render_payload(last_payload)
                    end)
                )
            )
        end

        event_list_layout:add(row)
        y_offset = y_offset + EVENT_HEIGHT + EVENT_SPACING

        if expanded_group_key == group.key then
            for idx = 1, #group.events do
                local detail_row = concurrent_detail_row(group.events[idx], idx)
                event_list_layout:add(detail_row)
                y_offset = y_offset + SUB_EVENT_HEIGHT + EVENT_SPACING
            end
        end
    end

    last_visible_events = visible
    last_visible_limit = limit
    scroll_to_current_event(visible, limit)
    schedule_scroll_timer(visible, limit)
end

update_time = function()
    header_time.markup = os.date('%I:%M %p')
end

local function refresh()
    local command = string.format('%q --days %d', fetch_script, window_days)
    awful.spawn.easy_async_with_shell(command, function(stdout)
        local payload = json.parse(stdout or '')
        render_payload(payload)
        update_time()
    end)
end

scroll_clip = wibox.widget {
    {
        {
            scroll_content,
            layout = wibox.layout.fixed.vertical,
        },
        bg = beautiful.transparent or '#00000000',
        shape = function(cr, w, h)
            gears.shape.rectangle(cr, w, h)
        end,
        widget = wibox.container.background,
    },
    strategy = 'max',
    height = MAX_HEIGHT,
    widget = wibox.container.constraint,
}

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

scroll_area:buttons(
    gears.table.join(
        awful.button({}, 4, nil, function()
            do_scroll('up')
        end),
        awful.button({}, 5, nil, function()
            do_scroll('down')
        end)
    )
)

refresh_button:buttons(
    gears.table.join(
        awful.button({}, 1, nil, refresh)
    )
)

awesome.connect_signal('widget::update_calendar', refresh)
refresh()

return wibox.widget {
    {
        {
            header_widget,
            nil,
            {
                count_badge,
                header_time,
                refresh_button,
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(8),
            },
            layout = wibox.layout.align.horizontal,
        },
        {
            scroll_area,
            top = dpi(8),
            widget = wibox.container.margin,
        },
        layout = wibox.layout.fixed.vertical,
    },
    bg = beautiful.transparent,
    widget = wibox.container.background,
}

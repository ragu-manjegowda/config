local awful = require('awful')
local gears = require('gears')
local wibox = require('wibox')
local naughty = require('naughty')
local beautiful = require('beautiful')
local email_subject = require('library.email-subject')
local email_refresh = require('library.email-refresh')
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/email/icons/'

local mails_path = config_dir .. 'widget/email/mails.txt'

local unread_email_count = 0
local unread_recent_email_from = ""
local unread_recent_email_subject = ""

local startup_show = true

-- Constants for scrollable email list
local EMAIL_HEIGHT = dpi(88)
local EMAIL_SPACING = dpi(5)
local MAX_HEIGHT = dpi(155)
local SCROLL_PADDING = dpi(30)
local MAX_SUBJECT_LINE_LENGTH = 42

local email_header = wibox.widget {
    text   = 'Email',
    font   = beautiful.font_bold(14),
    align  = 'left',
    valign = 'center',
    widget = wibox.widget.textbox
}

local email_count_widget = wibox.widget {
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
        top = 0,
        bottom = 0,
        widget = wibox.container.margin,
    },
    bg = beautiful.accent or beautiful.bg_focus,
    fg = beautiful.fg_focus or beautiful.fg_normal,
    shape = gears.shape.rounded_bar,
    visible = false,
    widget = wibox.container.background,
}

-- Layout for email items
local email_list_layout = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = EMAIL_SPACING,
}

-- Create a single email item widget
local function create_email_item(from, subject, date)
    local subject_line_one, subject_line_two = email_subject.split(subject, MAX_SUBJECT_LINE_LENGTH)
    local email_content = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(2),
        {
            markup = '<b>From:</b> ' .. gears.string.xml_escape(from),
            font = beautiful.font_regular(9),
            widget = wibox.widget.textbox,
        },
        {
            {
                markup = '<b>Subject:</b> ' .. gears.string.xml_escape(subject_line_one),
                font = beautiful.font_regular(9),
                widget = wibox.widget.textbox,
            },
            {
                text = subject_line_two,
                font = beautiful.font_regular(9),
                visible = subject_line_two ~= '',
                widget = wibox.widget.textbox,
            },
            layout = wibox.layout.fixed.vertical,
        },
        {
            markup = '<span foreground="#888888">' .. gears.string.xml_escape(date) .. '</span>',
            font = beautiful.font_regular(8),
            forced_height = dpi(12),
            widget = wibox.widget.textbox,
        },
    }

    local email_template = wibox.widget {
        {
            email_content,
            margins = dpi(10),
            widget = wibox.container.margin
        },
        bg = beautiful.background,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
        widget = wibox.container.background,
    }

    return wibox.widget {
        {
            -- Accent left border
            {
                forced_width = dpi(4),
                bg = beautiful.accent,
                widget = wibox.container.background,
            },
            -- Content area with inner background
            {
                email_template,
                left = dpi(8),
                right = dpi(8),
                top = 0,
                bottom = 0,
                widget = wibox.container.margin,
            },
            layout = wibox.layout.align.horizontal,
        },
        bg = beautiful.groups_bg,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
        forced_height = EMAIL_HEIGHT,
        widget = wibox.container.background,
    }
end

-- Empty state widget
local empty_email_widget = wibox.widget {
    {
        {
            {
                image = widget_icon_dir .. 'email.svg',
                resize = true,
                forced_height = dpi(30),
                forced_width = dpi(30),
                widget = wibox.widget.imagebox,
            },
            {
                text = 'No unread emails',
                font = beautiful.font_regular(10),
                widget = wibox.widget.textbox,
            },
            spacing = dpi(10),
            layout = wibox.layout.fixed.horizontal,
        },
        margins = dpi(15),
        widget = wibox.container.margin,
    },
    bg = beautiful.background,
    shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
    end,
    widget = wibox.container.background,
}

-- Initialize with empty state
email_list_layout:add(empty_email_widget)

local function update_email_count(count)
    local count_text = email_count_widget:get_children_by_id('count_text')[1]
    count_text.text = tostring(count)
    email_count_widget.visible = (count > 0)
end

-- Scroll state
local scroll_offset = 0
local max_scroll = 0
local content_height = 0
local visible_height = MAX_HEIGHT
local current_email_index = 1

-- Scrollbar widgets
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

-- Scroll content container
local scroll_content = wibox.widget {
    email_list_layout,
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
    height = MAX_HEIGHT,
    widget = wibox.container.constraint,
}

-- Function to update scrollbar and height
local function update_scrollbar(center_current)
    local child_count = #email_list_layout.children
    content_height = child_count * EMAIL_HEIGHT + (child_count - 1) * EMAIL_SPACING

    -- Dynamic height: use content height up to MAX_HEIGHT
    visible_height = math.min(content_height, MAX_HEIGHT)
    scroll_clip.height = visible_height
    scrollbar_track.forced_height = visible_height

    -- Add extra scroll space to ensure last item is fully visible
    max_scroll = math.max(0, content_height - MAX_HEIGHT + SCROLL_PADDING)
    current_email_index = math.max(1, math.min(current_email_index, child_count))
    if center_current then
        local stride = EMAIL_HEIGHT + EMAIL_SPACING
        scroll_offset = (current_email_index - 1) * stride - EMAIL_HEIGHT / 2
    end
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
    local old_index = current_email_index
    if direction == 'up' then
        current_email_index = math.max(1, current_email_index - 1)
    elseif direction == 'down' then
        current_email_index = math.min(#email_list_layout.children, current_email_index + 1)
    end
    if old_index ~= current_email_index then
        update_scrollbar(true)
    end
end

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

-- Main email widget
local email_report = wibox.widget {
    {
        {
            -- Header row
            {
                layout = wibox.layout.align.horizontal,
                expand = 'none',
                {
                    email_header,
                    {
                        email_count_widget,
                        left = dpi(8),
                        widget = wibox.container.margin,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                nil,
                nil
            },
            -- Spacing
            {
                forced_height = dpi(10),
                widget = wibox.container.background,
            },
            -- Email list
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

local notify_all_unread_email = function(email_data)
    local unread_counter = email_data:match('Unread Count: (.-)From:'):sub(1, -2)

    local title

    if tonumber(unread_email_count) > 1 then
        title = 'You have ' .. unread_counter .. ' unread emails!'
    else
        title = 'You have ' .. unread_counter .. ' unread email!'
    end

    naughty.notification({
        app_name = 'Email',
        retention_priority = 1,
        title = title,
        icon = widget_icon_dir .. 'email-unread.svg'
    })
end

local notify_new_email = function(count, from, subject)
    if not startup_show then
        if (unread_email_count == tonumber(count)) then
            if (unread_recent_email_from == from) then
                if (unread_recent_email_subject == subject) then
                    return
                end
            end
        end

        unread_email_count = tonumber(count) or 0
        unread_recent_email_from = from
        unread_recent_email_subject = subject

        local message = "From: " .. from ..
            "\nSubject: " .. subject

        naughty.notification({
            app_name = 'Email',
            retention_priority = 1,
            title = 'You have a new unread email!',
            message = message,
            timeout = 10,
            icon = widget_icon_dir .. 'email-unread.svg'
        })
    else
        unread_email_count = tonumber(count) or 0
        unread_recent_email_from = from
        unread_recent_email_subject = subject
    end
end

-- Parse all emails from the data
local function parse_emails(email_data)
    local emails = {}

    -- Pattern to match each email block
    -- Each email has: From: ...\nSubject: ...\nLocal Date: ...
    for from, subject, date in email_data:gmatch('From: (.-)\nSubject: (.-)\nLocal Date: (.-)\n') do
        -- Clean up the values
        local sender = from:gsub('%s+$', ''):gsub('\n', '')
        local clean_subject = subject:gsub('%s+$', ''):gsub('\n', '')
        local clean_date = date:gsub('%s+$', ''):gsub('\n', '')

        -- Extract email from angle brackets if present
        local email_addr = sender:match('<(.*)>') or sender:match('&lt;(.*)&gt;')
        if email_addr then
            sender = email_addr
        end

        table.insert(emails, {
            from = sender,
            subject = clean_subject,
            date = clean_date
        })
    end

    return emails
end

local set_no_connection_msg = function()
    email_list_layout:reset()
    email_list_layout:add(create_email_item(
        'message@stderr.sh',
        'Check network connection!',
        os.date('%d-%m-%Y %H:%M:%S')
    ))
    update_email_count(0)
    current_email_index = 1
    update_scrollbar(true)
end

local set_invalid_credentials_msg = function()
    email_list_layout:reset()
    email_list_layout:add(create_email_item(
        'message@stderr.sh',
        'Invalid Credentials!',
        os.date('%d-%m-%Y %H:%M:%S')
    ))
    update_email_count(0)
    current_email_index = 1
    update_scrollbar(true)
end

local set_empty_inbox_msg = function()
    email_list_layout:reset()
    email_list_layout:add(empty_email_widget)
    update_email_count(0)
    current_email_index = 1
    update_scrollbar(true)
end

local set_latest_email_data = function(email_data)
    local unread_count = email_data:match('Unread Count: (.-)From:')
    if unread_count then
        unread_count = unread_count:sub(1, -2)
    else
        unread_count = "0"
    end

    local emails = parse_emails(email_data)

    email_list_layout:reset()

    if #emails > 0 then
        for _, email in ipairs(emails) do
            email_list_layout:add(create_email_item(
                email.from,
                email.subject,
                email.date
            ))
        end

        update_email_count(tonumber(unread_count) or #emails)

        -- Notify about the most recent email
        notify_new_email(unread_count, emails[1].from, emails[1].subject)
    else
        email_list_layout:add(empty_email_widget)
        update_email_count(0)
    end

    current_email_index = 1
    update_scrollbar(true)
end

local fetch_email_data = function()
    local command = string.format('cat %s', tostring(mails_path))

    awful.spawn.easy_async(command, function(stdout, stderr, _, exitcode)
        if exitcode == 0 then
            if stdout:match('Temporary failure in name resolution') then
                set_no_connection_msg()
                return
            elseif stdout:match('Invalid credentials') then
                set_invalid_credentials_msg()
                return
            elseif stdout:match('Unread Count: 0') then
                set_empty_inbox_msg()
                return
            elseif not stdout:match('Unread Count: (.-)From:') then
                return
            elseif not stdout or stdout == '' then
                return
            end

            set_latest_email_data(stdout)

            if startup_show then
                notify_all_unread_email(stdout)
                startup_show = false
            end
        else
            naughty.notification({
                app_name = 'Email',
                retention_priority = 1,
                title = 'Read error',
                message = stderr,
                icon = widget_icon_dir .. 'email-unread.svg'
            })
            return
        end
    end)
end

-- Emitted from Imapnotify
awesome.connect_signal(
    'module::email:show',
    function()
        fetch_email_data()
    end
)

-- Initial scrollbar update
gears.timer.start_new(0.5, function()
    update_scrollbar()
    fetch_email_data()
    return false
end)

-- Periodic refresh timer (every 5 minutes)
-- Workaround for Exchange/Outlook not sending EXPUNGE notifications during IDLE
local REFRESH_INTERVAL = 300 -- 5 minutes in seconds
local notify_script = os.getenv("HOME") .. "/.config/imapnotify/notify.sh"
local should_refresh_emails = email_refresh.new {
    mails_path = mails_path,
    notify_script = notify_script,
    spawn = awful.spawn.easy_async,
}

-- Start the periodic refresh timer
gears.timer {
    timeout = REFRESH_INTERVAL,
    autostart = true,
    callback = should_refresh_emails
}

return email_report

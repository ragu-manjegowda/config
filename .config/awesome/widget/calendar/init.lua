-------------------------------------------------
-- Calendar Widget for Awesome Window Manager
-- Shows the current month and supports scroll up/down to switch month
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/calendar-widget

-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov

-- @modified-by Ragu Manjegowda
-- @github      ragu-manjegowda
-------------------------------------------------

local awful               = require("awful")
local beautiful           = require("beautiful")
local wibox               = require("wibox")
local gears               = require("gears")
local clickable_container = require('widget.clickable-container')
local navigation          = require('library.calendar-navigation')
local holiday_data        = require('library.calendar-holidays')
local json                = require('library.json')
local config              = require('configuration.config')
local config_dir          = gears.filesystem.get_configuration_dir()
local widget_icon_dir     = config_dir .. 'widget/calendar/icons/'
local dpi                 = beautiful.xresources.apply_dpi

local bg                  = beautiful.transparent
local fg                  = beautiful.fg_normal
local focus_date_bg       = beautiful.accent
local focus_date_fg       = beautiful.fg_focus
local weekend_day_bg      = beautiful.fg_normal
local weekend_day_fg      = beautiful.groups_bg

local start_sunday        = false
local state               = navigation.new(os.date('*t'))
local holiday_cfg         = config.widget.calendar_holidays or {}
local cache_file          = (os.getenv('XDG_CACHE_HOME') or (os.getenv('HOME') .. '/.cache'))
    .. '/awesome/calendar-holidays.json'
local holiday_dates       = {}
local holiday_cells       = {}
local sync_in_progress    = false
local render, begin_prompt, refresh_holidays
local holiday_tooltip     = awful.tooltip {
    mode = 'outside', align = 'right', text = '', preferred_positions = { 'top', 'bottom', 'right', 'left' },
}

local function text_button(text, callback)
    local button = wibox.widget {
        {
            {
                text = text,
                font = beautiful.font_bold(14),
                align = 'center',
                valign = 'center',
                widget = wibox.widget.textbox,
            },
            left = dpi(8), right = dpi(8), top = dpi(4), bottom = dpi(4),
            widget = wibox.container.margin,
        },
        widget = clickable_container,
    }
    button = wibox.widget {
        button,
        bg = beautiful.background,
        shape = gears.shape.rounded_bar,
        widget = wibox.container.background,
    }
    button:buttons(gears.table.join(awful.button({}, 1, nil, callback)))
    return button
end

local function month_header(date)
    return wibox.widget {
        {
            text_button(os.date('%B', os.time { year = date.year, month = date.month, day = 1 }), function()
                state:show('months')
                render()
            end),
            text_button(tostring(date.year), function()
                state:show('years')
                render()
            end),
            spacing = dpi(6),
            layout = wibox.layout.fixed.horizontal,
        },
        id = 'calendar_month_year_header',
        halign = 'center',
        widget = wibox.container.place,
    }
end

local styles = {}
local function rounded_shape(size)
    return function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, size)
    end
end

styles.month = {
    padding = 4,
    bg_color = bg,
    border_width = 0,
}

styles.normal = {
    markup = function(t) return t end,
    shape = rounded_shape(4)
}

styles.focus = {
    fg_color = focus_date_fg,
    bg_color = focus_date_bg,
    markup = function(t) return '<b>' .. t .. '</b>' end,
    shape = rounded_shape(4)
}

styles.header = {
    fg_color = fg,
    bg_color = bg,
    markup = function(t) return '<b>' .. t .. '</b>' end
}

styles.weekday = {
    fg_color = fg,
    bg_color = bg,
    markup = function(t) return '<b>' .. t .. '</b>' end,
}

local function decorate_cell(widget, flag, date)
    if flag == 'monthheader' and not styles.monthheader then
        flag = 'header'
    end
    if flag == 'header' then return month_header(date) end

    -- highlight only today's day
    if flag == 'focus' then
        local today = os.date('*t')
        if not (today.month == date.month and today.year == date.year) then
            flag = 'normal'
        end
    end

    local props = styles[flag] or {}
    if props.markup and widget.get_text and widget.set_markup then
        widget:set_markup(props.markup(widget:get_text()))
    end
    -- Change bg color for weekends
    local d = { year = date.year, month = (date.month or 1), day = (date.day or 1) }
    local weekday = tonumber(os.date('%w', os.time(d)))
    local is_weekend = (weekday == 0 or weekday == 6)
        and (flag == 'normal' or flag == 'weekday')
    local cell_bg = is_weekend and weekend_day_bg or (props.bg_color or bg)
    local cell_fg = is_weekend and weekend_day_fg or (props.fg_color or fg)
    local entries = (flag == 'normal' or flag == 'focus') and holiday_dates[navigation.key(date)] or nil
    local border_color, border_width = props.border_color or '#000000', props.border_width or 0
    if entries then
        border_color = beautiful.system_cyan_light
        for _, event in ipairs(entries) do
            if event.source == 'work' then border_color = beautiful.system_magenta_light end
        end
        border_width = dpi(2)
    elseif state.day == date.day and state.month == date.month and state.year == date.year
        and flag == 'normal' then
        border_color, border_width = beautiful.accent, dpi(1)
    end
    local ret = wibox.widget {
        {
            {
                widget,
                halign = 'center',
                widget = wibox.container.place
            },
            margins = dpi(0),
            widget = wibox.container.margin
        },
        shape = props.shape,
        border_color = border_color,
        border_width = border_width,
        fg = cell_fg,
        bg = cell_bg,
        widget = wibox.container.background
    }

    if entries then
        ret:connect_signal('mouse::enter', function()
            holiday_tooltip:set_text(holiday_data.tooltip(entries))
        end)
        holiday_tooltip:add_to_object(ret)
        holiday_cells[#holiday_cells + 1] = ret
    end
    if flag == 'normal' or flag == 'focus' then
        ret:buttons(gears.table.join(awful.button({}, 1, nil, function()
            state:select_date(date.year, date.month, date.day)
            render()
        end)))
    end

    return ret
end

local cal = wibox.widget {
    date = os.date('*t'),
    font = beautiful.font_regular(14),
    spacing = { horizontal = dpi(6), vertical = 5 },
    fn_embed = decorate_cell,
    long_weekdays = true,
    start_sunday = start_sunday,
    widget = wibox.widget.calendar.month
}

local function nav_button(icon_path)
    return wibox.widget {
        {
            {
                {
                    image = icon_path,
                    resize = true,
                    forced_width = dpi(20),
                    forced_height = dpi(20),
                    widget = wibox.widget.imagebox,
                },
                margins = dpi(4),
                widget = wibox.container.margin,
            },
            widget = clickable_container,
        },
        forced_width = dpi(28),
        forced_height = dpi(28),
        bg = beautiful.accent,
        shape = gears.shape.circle,
        widget = wibox.container.background,
    }
end

local action_level_left = nav_button(widget_icon_dir .. 'left-arrow.svg')
local action_level_right = nav_button(widget_icon_dir .. 'right-arrow.svg')

-- Keep the arrows close to the calendar's natural width on wider panels.
local month_row = wibox.widget {
    {
        action_level_left,
        halign = 'center',
        valign = 'center',
        widget = wibox.container.place,
    },
    cal,
    {
        action_level_right,
        halign = 'center',
        valign = 'center',
        widget = wibox.container.place,
    },
    spacing = dpi(10),
    layout = wibox.layout.fixed.horizontal
}

local calendar_body = wibox.widget {
    {
        month_row,
        halign = 'center',
        widget = wibox.container.place,
    },
    widget = wibox.container.background,
}

local prompt_box = wibox.widget {
    id = 'calendar_date_input',
    text = '', font = beautiful.font_regular(12),
    widget = wibox.widget.textbox,
}
local prompt_card = wibox.widget {
    {
        prompt_box,
        left = dpi(10), right = dpi(10), top = dpi(6), bottom = dpi(6),
        widget = wibox.container.margin,
    },
    id = 'calendar_date_input_card',
    bg = beautiful.background,
    fg = beautiful.fg_normal,
    border_color = beautiful.background,
    border_width = 0,
    shape = gears.shape.rounded_bar,
    widget = wibox.container.background,
}
local date_tooltip = awful.tooltip {
    objects = { prompt_card }, mode = 'outside', align = 'right',
    preferred_positions = { 'top', 'bottom', 'right', 'left' },
    text = 'format: `yyyy-mm-dd` or `yyyy-mm` or `yyyy`'
        .. '\n press: `enter` to apply or `escape` to cancel',
}
local prompt_error = wibox.widget {
    text = '', font = beautiful.font_regular(10), visible = false,
    widget = wibox.widget.textbox,
}
local date_input = ''
local footer_actions, prompt_row
local prompt_grabber, caret_timer, prompt_owner, owner_hidden_handler
local caret_visible = false
local hover_wibox, hover_cursor
local function restore_input_cursor()
    if hover_wibox then hover_wibox.cursor = hover_cursor end
    hover_wibox, hover_cursor = nil, nil
end
local function update_prompt_text()
    local caret = caret_visible and '|' or ' '
    prompt_box.text = date_input == '' and (caret .. 'YYYY-MM-DD') or (date_input .. caret)
    prompt_box.opacity = date_input == '' and 0.55 or 1
end
local function reset_prompt_ui()
    if caret_timer then caret_timer:stop() end
    caret_visible = false
    date_input = ''
    prompt_box.text = ''
    prompt_row.visible = false
    prompt_error.visible = false
    prompt_card.border_color = beautiful.background
    prompt_card.border_width = 0
    date_tooltip.visible = false
    restore_input_cursor()
    footer_actions.visible = true
end
prompt_grabber = awful.keygrabber {
    keypressed_callback = function(self, modifiers, key)
        if key == 'Escape' then
            self:stop()
            return
        elseif key == 'Return' or key == 'KP_Enter' then
            local valid = state:jump(date_input)
            if valid then
                self:stop()
                render()
            else
                prompt_error.text = 'Enter a valid YYYY-MM-DD, YYYY-MM or YYYY'
                prompt_error.visible = true
                prompt_card.border_color = beautiful.system_red_light or beautiful.accent
                prompt_card.border_width = dpi(1)
            end
            return
        elseif key == 'BackSpace' then
            date_input = date_input:sub(1, -2)
        elseif key == 'u' and gears.table.hasitem(modifiers, 'Control') then
            date_input = ''
        else
            local character = key:match('^KP_(%d)$') or key
            if character == 'minus' or character == 'KP_Subtract' then character = '-' end
            if character:match('^[%d%-]$') and #date_input < 10 then
                date_input = date_input .. character
            end
        end
        prompt_error.visible = false
        prompt_card.border_color = beautiful.background
        prompt_card.border_width = 0
        caret_visible = true
        update_prompt_text()
    end,
    stop_callback = reset_prompt_ui,
}
caret_timer = gears.timer {
    timeout = 0.5,
    callback = function()
        if awful.keygrabber.current_instance ~= prompt_grabber then
            reset_prompt_ui()
            return
        end
        caret_visible = not caret_visible
        update_prompt_text()
    end,
}
prompt_row = wibox.widget {
    prompt_card,
    id = 'calendar_date_prompt',
    visible = false,
    bg = beautiful.transparent,
    widget = wibox.container.background,
}
begin_prompt = function()
    if awful.keygrabber.current_instance == prompt_grabber then
        caret_visible = true
        update_prompt_text()
        caret_timer:again()
        return
    end
    if awful.keygrabber.current_instance then return end
    if prompt_grabber.grabber then prompt_grabber:stop() end
    prompt_grabber:start()
    if awful.keygrabber.current_instance ~= prompt_grabber then return end
    prompt_error.visible = false
    prompt_card.border_color = beautiful.background
    prompt_card.border_width = 0
    date_input = ''
    caret_visible = true
    update_prompt_text()
    prompt_row.visible = true
    footer_actions.visible = false
    caret_timer:start()
end
prompt_card:buttons(gears.table.join(awful.button({}, 1, nil, begin_prompt)))
prompt_card:connect_signal('mouse::enter', function()
    local target = mouse and mouse.current_wibox
    if target then
        if hover_wibox ~= target then
            restore_input_cursor()
            hover_wibox, hover_cursor = target, target.cursor
        end
        target.cursor = 'hand1'
    end
end)
prompt_card:connect_signal('mouse::leave', restore_input_cursor)

local refresh_button = nav_button(config_dir .. 'widget/weather/icons/refresh.svg')
local sync_tooltip = awful.tooltip {
    objects = { refresh_button }, text = 'Refresh US and available work holidays',
}
footer_actions = wibox.widget {
    text_button('Today', function()
        local today = os.date('*t')
        state:select_date(today.year, today.month, today.day)
        render()
    end),
    text_button('Go to date', begin_prompt),
    refresh_button,
    spacing = dpi(8),
    layout = wibox.layout.fixed.horizontal,
}

local cal_widget = wibox.widget {
    {
        calendar_body,
        {
            footer_actions, halign = 'center', widget = wibox.container.place,
        },
        prompt_row,
        prompt_error,
        spacing = dpi(8),
        layout = wibox.layout.fixed.vertical,
    },
    bg = beautiful.transparent,
    widget = wibox.container.background
}

local function clear_tooltips()
    holiday_tooltip.visible = false
    for _, cell in ipairs(holiday_cells) do holiday_tooltip:remove_from_object(cell) end
    holiday_cells = {}
end

local function selector()
    local grid = wibox.widget {
        forced_num_cols = 3, homogeneous = true, spacing = dpi(6),
        layout = wibox.layout.grid,
    }
    local header
    if state.mode == 'months' then
        header = text_button(tostring(state.year), function()
            state:show('years'); render()
        end)
        for month = 1, 12 do
            local selected_month = month
            grid:add(text_button(os.date('%b', os.time { year = state.year, month = month, day = 1 }), function()
                state:select_month(selected_month)
                render()
            end))
        end
    else
        local years = state:years()
        header = text_button(years[1] .. ' – ' .. years[#years], begin_prompt)
        for _, year in ipairs(years) do
            local selected_year = year
            grid:add(text_button(tostring(year), function()
                state:select_year(selected_year)
                render()
            end))
        end
    end
    local choices = wibox.widget {
        { header, halign = 'center', widget = wibox.container.place },
        grid, spacing = dpi(8), layout = wibox.layout.fixed.vertical,
    }
    return wibox.widget {
        { action_level_left,  valign = 'center', widget = wibox.container.place },
        choices,
        { action_level_right, valign = 'center', widget = wibox.container.place },
        spacing = dpi(10), layout = wibox.layout.fixed.horizontal,
    }
end

render = function()
    clear_tooltips()
    local view
    if state.mode == 'month' then
        local today = os.date('*t')
        local date = { year = state.year, month = state.month }
        if today.year == state.year and today.month == state.month then date.day = today.day end
        cal:set_date(nil)
        cal:set_date(date)
        view = month_row
    else
        view = selector()
    end
    calendar_body:set_widget(wibox.widget {
        view, halign = 'center', widget = wibox.container.place,
    })
end

local function apply_holidays(payload)
    if type(payload) ~= 'table' or payload.ok ~= true then return end
    holiday_dates = holiday_data.index(payload)
    local errors = type(payload.errors) == 'table' and table.concat(payload.errors, '\n') or ''
    local window = payload.window or {}
    local work_count = 0
    for _, event in ipairs(payload.events or {}) do
        if event.source == 'work' then work_count = work_count + 1 end
    end
    local work_status = payload.work_calendar_available
        and ('\nWork calendar: ' .. work_count .. ' holiday dates')
        or '\nWork calendar: no existing login available'
    sync_tooltip:set_text('Holidays: ' .. (window.start or '') .. ' to ' .. (window['end'] or '')
        .. work_status .. (errors ~= '' and ('\nCached/offline fallback:\n' .. errors) or '\nUp to date'))
    render()
end

refresh_holidays = function(force)
    if sync_in_progress then return end
    sync_in_progress = true
    local script = holiday_cfg.script or (config_dir .. 'utilities/network/calendar-holidays')
    local command = { '/usr/bin/timeout', '--kill-after=2', '50', '/usr/bin/python3', script,
        '--cache', cache_file }
    if holiday_cfg.company_pattern then
        command[#command + 1] = '--company-pattern'
        command[#command + 1] = holiday_cfg.company_pattern
    end
    if force then command[#command + 1] = '--force' end
    awful.spawn.easy_async(command, function(stdout, _, _, exit_code)
        sync_in_progress = false
        local ok, payload = pcall(json.parse, stdout)
        if exit_code == 0 and ok and type(payload) == 'table' and payload.ok then
            apply_holidays(payload)
        else
            sync_tooltip:set_text('Holiday sync unavailable; existing markers retained')
        end
    end)
end

function cal_widget:update()
    local today = os.date('*t')
    state:select_date(today.year, today.month, today.day)
    render()
    refresh_holidays(false)
end

function cal_widget:stop_prompt()
    if awful.keygrabber.current_instance == prompt_grabber then
        prompt_grabber:stop()
    else
        reset_prompt_ui()
    end
    holiday_tooltip.visible = false
end

function cal_widget:set_input_owner(owner)
    if prompt_owner == owner then return end
    self:stop_prompt()
    if prompt_owner and owner_hidden_handler then
        prompt_owner:disconnect_signal('property::visible', owner_hidden_handler)
    end
    prompt_owner = owner
    owner_hidden_handler = function()
        if not owner.visible then self:stop_prompt() end
    end
    owner:connect_signal('property::visible', owner_hidden_handler)
end

local function release_calendar_input()
    if awful.keygrabber.current_instance == prompt_grabber then cal_widget:stop_prompt() end
end
if wibox.connect_signal then
    wibox.connect_signal('button::press', function(target, x, y)
        if awful.keygrabber.current_instance ~= prompt_grabber then return end
        if target == prompt_owner and x and y and target.find_widgets then
            for _, hit in ipairs(target:find_widgets(x, y)) do
                if hit.widget == prompt_card then return end
            end
        end
        release_calendar_input()
    end)
end
if client and client.connect_signal then
    client.connect_signal('focus', release_calendar_input)
    client.connect_signal('button::press', release_calendar_input)
end
if awful.mouse and awful.mouse.append_global_mousebindings then
    awful.mouse.append_global_mousebindings {
        awful.button { button = 1, on_press = release_calendar_input },
        awful.button { button = 2, on_press = release_calendar_input },
        awful.button { button = 3, on_press = release_calendar_input },
    }
end
awful.keygrabber.connect_signal('property::current_instance', function(current)
    if current ~= prompt_grabber and prompt_row.visible then reset_prompt_ui() end
end)

function cal_widget:get_navigation_state()
    return { year = state.year, month = state.month, day = state.day, mode = state.mode }
end

action_level_left:buttons(
    awful.util.table.join(
        awful.button({}, 1, nil, function()
            state:step(-1)
            render()
        end)
    )
)

action_level_right:buttons(
    awful.util.table.join(
        awful.button({}, 1, nil, function()
            state:step(1)
            render()
        end)
    )
)

refresh_button:buttons(gears.table.join(awful.button({}, 1, nil, function() refresh_holidays(true) end)))
awesome.connect_signal('module::locked', function() cal_widget:stop_prompt() end)
local file = io.open(cache_file, 'r')
if file then
    local ok, payload = pcall(json.parse, file:read('*a'))
    file:close()
    if ok then apply_holidays(payload) end
end
render()

return cal_widget

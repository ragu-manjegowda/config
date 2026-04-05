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
local config_dir          = gears.filesystem.get_configuration_dir()
local widget_icon_dir     = config_dir .. 'widget/calendar/icons/'
local dpi                 = beautiful.xresources.apply_dpi

local bg                  = beautiful.transparent
local fg                  = beautiful.fg_normal
local focus_date_bg       = beautiful.accent
local focus_date_fg       = beautiful.fg_focus
local weekend_day_bg      = beautiful.bg_focus

local start_sunday        = false

local styles              = {}
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
    local default_bg = (weekday == 0 or weekday == 6)
        and weekend_day_bg
        or bg
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
        shape_border_color = props.border_color or '#000000',
        shape_border_width = props.border_width or 0,
        fg = props.fg_color or fg,
        bg = props.bg_color or default_bg,
        widget = wibox.container.background
    }

    return ret
end

local function days_in_month(year, month)
    return os.date('*t', os.time({ year = year, month = month + 1, day = 0 })).day
end

local function month_weeks_count(year, month)
    local first_weekday = tonumber(os.date('%w', os.time({ year = year, month = month, day = 1 })))
    local leading_days = first_weekday
    if not start_sunday then
        leading_days = (first_weekday + 6) % 7
    end

    local total_cells = leading_days + days_in_month(year, month)
    return math.ceil(total_cells / 7)
end

local function month_widget_height(date)
    local weeks = month_weeks_count(date.year, date.month)
    local header_height = dpi(66)
    local week_row_height = dpi(24)
    local top_bottom_padding = dpi(8)
    return header_height + (weeks * week_row_height) + top_bottom_padding
end

local cal = wibox.widget {
    date = os.date('*t'),
    font = beautiful.font_regular(14),
    fn_embed = decorate_cell,
    long_weekdays = true,
    start_sunday = start_sunday,
    widget = wibox.widget.calendar.month
}

local function move_month(delta)
    local current = cal:get_date()
    local month = current.month + delta
    local year = current.year

    while month < 1 do
        month = month + 12
        year = year - 1
    end

    while month > 12 do
        month = month - 12
        year = year + 1
    end

    local today = os.date('*t')
    local day = 1
    if year == today.year and month == today.month then
        day = today.day
    end

    cal:set_date(nil)
    cal:set_date({ year = year, month = month, day = day })
end

local function nav_button(icon_path)
    return wibox.widget {
        {
            {
                {
                    image = icon_path,
                    resize = true,
                    widget = wibox.widget.imagebox,
                },
                halign = 'center',
                valign = 'center',
                widget = wibox.container.place,
            },
            widget = clickable_container,
        },
        bg = beautiful.groups_bg,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
        end,
        widget = wibox.container.background,
    }
end

local action_level_left = nav_button(widget_icon_dir .. 'left-arrow.svg')
local action_level_right = nav_button(widget_icon_dir .. 'right-arrow.svg')

local w = wibox.widget {
    action_level_left,
    cal,
    action_level_right,
    layout = wibox.layout.ratio.horizontal
}

w:adjust_ratio(2, 0.08, 0.84, 0.08)

local calendar_body = wibox.widget {
    w,
    forced_height = month_widget_height(cal:get_date()),
    widget = wibox.container.background,
}

local function apply_month_height()
    calendar_body.forced_height = month_widget_height(cal:get_date())
end

local cal_widget = wibox.widget {
    {
        calendar_body,
        widget = wibox.container.background,
    },
    bg = beautiful.transparent,
    widget = wibox.container.background
}

function cal_widget:update()
    local date = os.date('*t')
    cal:set_date(date)
    apply_month_height()
end

action_level_left:buttons(
    awful.util.table.join(
        awful.button({}, 1, nil, function()
            move_month(-1)
            apply_month_height()
        end)
    )
)

action_level_right:buttons(
    awful.util.table.join(
        awful.button({}, 1, nil, function()
            move_month(1)
            apply_month_height()
        end)
    )
)

return cal_widget

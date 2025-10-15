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

local cal = wibox.widget {
    date = os.date('*t'),
    font = beautiful.font_regular(14),
    fn_embed = decorate_cell,
    long_weekdays = true,
    start_sunday = start_sunday,
    widget = wibox.widget.calendar.month
}

local icon_left = wibox.widget {
    layout = wibox.layout.align.vertical,
    expand = 'none',
    nil,
    {
        image = widget_icon_dir .. 'left-arrow' .. '.svg',
        resize = true,
        widget = wibox.widget.imagebox
    },
    nil
}

local icon_right = wibox.widget {
    layout = wibox.layout.align.vertical,
    expand = 'none',
    nil,
    {
        image = widget_icon_dir .. 'right-arrow' .. '.svg',
        resize = true,
        widget = wibox.widget.imagebox
    },
    nil
}

local action_level_left = wibox.widget {
    {
        {
            icon_left,
            widget = wibox.container.margin
        },
        widget = clickable_container,
    },
    bg = beautiful.groups_bg,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
    end,
    widget = wibox.container.background
}

action_level_left:buttons(
    awful.util.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                local a = cal:get_date()
                a.month = a.month - 1
                cal:set_date(nil)
                cal:set_date(a)
            end
        )
    )
)

local action_level_right = wibox.widget {
    {
        {
            icon_right,
            widget = wibox.container.margin
        },
        widget = clickable_container,
    },
    bg = beautiful.groups_bg,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
    end,
    widget = wibox.container.background
}

action_level_right:buttons(
    awful.util.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                local a = cal:get_date()
                a.month = a.month + 1
                cal:set_date(nil)
                cal:set_date(a)
            end
        )
    )
)

local w = wibox.widget {
    action_level_left,
    cal,
    action_level_right,
    layout = wibox.layout.ratio.horizontal
}

w:inc_ratio(2, 0.5)

local cal_widget = wibox.widget {
    {
        w,
        forced_height = dpi(200),
        widget        = wibox.container.background,
    },
    bg = beautiful.transparent,
    widget = wibox.container.background
}

function cal_widget:update()
    local date = os.date('*t')
    cal:set_date(date)
end

return cal_widget

-------------------------------------------------
-- @reference https://github.com/clistoq/yadr
-------------------------------------------------

local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local playerctl_daemon = require("library.bling").signal.playerctl.cli()

local function rounded_shape(size)
    return function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, size)
    end
end

local art = wibox.widget {
    image = gears.filesystem.get_configuration_dir() .. "widget/playerctl/icons/default.png",
    resize = true,
    upscale = true,
    vertical_fit_policy = "fit",
    forced_height = dpi(80),
    forced_width = dpi(80),
    clip_shape = rounded_shape(4),
    widget = wibox.widget.imagebox
}

local get_time_from_minutes = function(minutes)
    local hour = 0
    local min = 0
    local seconds = 0
    if minutes > 1 then
        min = math.floor(minutes / 60)
        if min > 60 then
            hour = math.floor(min / 60)
            min = math.floor(min % 60)
        end
    end
    seconds = math.floor(minutes % 60)

    local hour_str = ""
    if hour < 10 then
        hour_str = '0' .. tostring(hour)
    else
        hour_str = tostring(hour)
    end

    local min_str = ""
    if min < 10 then
        min_str = '0' .. tostring(min)
    else
        min_str = tostring(min)
    end

    local seconds_str = ""
    if seconds < 10 then
        seconds_str = '0' .. tostring(seconds)
    else
        seconds_str = tostring(seconds)
    end

    local time = ""
    if hour > 0 then
        time = hour_str .. ':' .. min_str .. ':' .. seconds_str
    else
        time = min_str .. ':' .. seconds_str
    end

    return time
end

local old_cursor, old_wibox

local create_button = function(symbol, color, command, playpause)
    local icon = wibox.widget {
        markup = "<span foreground='" .. color .. "'>" .. symbol .. "</span>",
        font = "Hack Nerd Font Mono 20",
        align = "center",
        valigin = "center",
        widget = wibox.widget.textbox()
    }

    local button = wibox.widget {
        icon,
        forced_height = dpi(30),
        forced_width = dpi(30),
        widget = wibox.container.background
    }

    playerctl_daemon:connect_signal(
        "playback_status", function(_, playing, _)
            if playpause then
                if playing then
                    icon.markup = "<span foreground='" .. color .. "'>" .. "󰏤" .. "</span>"
                else
                    icon.markup = "<span foreground='" .. color .. "'>" .. "󰐊" .. "</span>"
                end
            end
        end)

    button:buttons(gears.table.join(
        awful.button({}, 1, function() command() end)))

    button:connect_signal(
        "mouse::enter",
        function()
            icon.markup = "<span foreground='" .. beautiful.fg_normal
                .. "'>" .. icon.text .. "</span>"

            local w = mouse.current_wibox
            if w then
                old_cursor, old_wibox = w.cursor, w
                w.cursor = 'hand1'
            end
        end
    )

    button:connect_signal(
        "mouse::leave",
        function()
            icon.markup = "<span foreground='" .. color .. "'>"
                .. icon.text .. "</span>"

            if old_wibox then
                old_wibox.cursor = old_cursor
                old_wibox = nil
            end
        end
    )

    return button
end

local title_widget = wibox.widget {
    markup = 'Nothing Playing',
    align = 'center',
    valign = 'center',
    ellipsize = 'middle',
    widget = wibox.widget.textbox
}

local artist_widget = wibox.widget {
    markup = 'Nothing Playing',
    align = 'center',
    valign = 'center',
    ellipsize = 'middle',
    wrap = 'word_char',
    widget = wibox.widget.textbox
}

local current_time = wibox.widget {
    text = '00:00',
    font = 'Hack Nerd Bold 12',
    align = 'left',
    widget = wibox.widget.textbox
}

local end_time = wibox.widget {
    text = '00:00',
    font = 'Hack Nerd Regular 12',
    align = 'right',
    widget = wibox.widget.textbox
}

local slider = wibox.widget {
    nil,
    {
        id                  = 'blur_strength_slider',
        bar_shape           = gears.shape.rounded_rect,
        bar_height          = dpi(24),
        bar_color           = beautiful.fg_focus,
        bar_active_color    = beautiful.accent,
        handle_color        = beautiful.accent,
        handle_shape        = gears.shape.circle,
        handle_width        = dpi(24),
        handle_border_color = beautiful.background,
        handle_border_width = dpi(1),
        maximum             = 100,
        widget              = wibox.widget.slider
    },
    nil,
    expand = 'none',
    forced_height = dpi(10),
    layout = wibox.layout.align.vertical
}

local seek_slider = slider.blur_strength_slider

-- Get Song Info
playerctl_daemon:connect_signal("metadata",
    function(_, title, artist, album_path, _, _, _)
        if title == "" then
            title = "Nothing Playing"
        end
        if artist == "" then
            artist = "Nothing Playing"
        end
        if album_path == "" then
            album_path = gears.filesystem.get_configuration_dir() .. "widget/playerctl/icons/default.png"
        end

        -- Set art widget
        art:set_image(gears.surface.load_uncached(album_path))

        -- Set, title and artist widgets
        title_widget:set_markup_silently(
            '<span foreground="' .. beautiful.accent .. '">' .. title .. '</span>')
        artist_widget:set_markup_silently(
            '<span foreground="' .. beautiful.accent .. '">' .. artist .. '</span>')

        seek_slider.value = 0
        current_time:set_text("00:00")
        end_time:set_text("00:00")
    end)

playerctl_daemon:connect_signal("no_players", function(_)
    local title = "Nothing Playing"
    local artist = "Nothing Playing"
    local album_path = gears.filesystem.get_configuration_dir() .. "widget/playerctl/icons/default.png"

    -- Set art widget
    -- Strings are assumed to be file names and get loaded
    ---@diagnostic disable-next-line: param-type-mismatch
    art:set_image(gears.surface.load_uncached(album_path))

    -- Set, title and artist widgets
    title_widget:set_markup_silently(
        '<span foreground="' .. beautiful.accent .. '">' .. title .. '</span>')
    artist_widget:set_markup_silently(
        '<span foreground="' .. beautiful.accent .. '">' .. artist .. '</span>')

    seek_slider.value = 0
    current_time:set_text("00:00")
    end_time:set_text("00:00")
end)

local play_command = function()
    playerctl_daemon:play_pause()
end

local prev_command = function()
    playerctl_daemon:previous()
end

local next_command = function()
    playerctl_daemon:next()
end

local playerctl_play_symbol = create_button("󰐊", beautiful.fg_normal,
    play_command, true)

local playerctl_prev_symbol = create_button("󰒮", beautiful.fg_normal,
    prev_command, false)
local playerctl_next_symbol = create_button("󰒭", beautiful.fg_normal,
    next_command, false)

local time_info = wibox.widget {
    layout = wibox.layout.align.horizontal,
    current_time,
    nil,
    end_time
}

local total_length_in_sec = 0

playerctl_daemon:connect_signal(
    "position", function(_, interval_sec, length_sec, _)
        seek_slider.value = (interval_sec / length_sec) * 100
        current_time:set_text(get_time_from_minutes(interval_sec))
        end_time:set_text(get_time_from_minutes(length_sec))
        total_length_in_sec = length_sec
    end
)

seek_slider:connect_signal(
    "mouse::enter",
    function()
        local w = mouse.current_wibox
        if w then
            old_cursor, old_wibox = w.cursor, w
            w.cursor = 'hand1'
        end
    end
)

seek_slider:connect_signal(
    "mouse::leave",
    function()
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end
)

seek_slider:connect_signal(
    "button::press",
    function(_, lx, _, _, _, w)
        local seek_value = math.ceil(lx * 100 / w.width)
        local seek_position = (seek_value / 100) * total_length_in_sec
        playerctl_daemon:set_position(seek_position)
    end
)

local scroll_container = function(widget)
    return wibox.widget {
        widget,
        id = 'scroll_container',
        max_size = 345,
        speed = 75,
        expand = true,
        direction = 'h',
        step_function = wibox.container.scroll
            .step_functions.waiting_nonlinear_back_and_forth,
        fps = 30,
        layout = wibox.container.scroll.horizontal,
    }
end

local playerctl = wibox.widget {
    {
        art,
        left = dpi(5),
        top = dpi(5),
        bottom = dpi(5),
        layout = wibox.container.margin
    },
    {
        {
            {
                {
                    scroll_container(title_widget),
                    scroll_container(artist_widget),
                    layout = wibox.layout.fixed.vertical
                },
                top = 10,
                left = 25,
                right = 25,
                widget = wibox.container.margin
            },
            {
                nil,
                {
                    playerctl_prev_symbol,
                    playerctl_play_symbol,
                    playerctl_next_symbol,
                    spacing = dpi(40),
                    layout = wibox.layout.fixed.horizontal
                },
                nil,
                expand = "none",
                layout = wibox.layout.align.horizontal
            },
            {
                {
                    slider,
                    top = dpi(10),
                    left = dpi(25),
                    right = dpi(25),
                    widget = wibox.container.margin
                },
                {
                    {
                        layout = wibox.layout.align.vertical,
                        expand = 'none',
                        nil,
                        time_info,
                        nil
                    },
                    top = 10,
                    left = 25,
                    right = 25,
                    widget = wibox.container.margin
                },
                spacing = dpi(5),
                layout = wibox.layout.fixed.vertical
            },
            layout = wibox.layout.align.vertical
        },
        top = dpi(0),
        bottom = dpi(10),
        widget = wibox.container.margin
    },
    layout = wibox.layout.align.horizontal
}

return playerctl

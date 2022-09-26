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
local naughty = require("naughty")

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
        "playback_status", function(_, playing, player_name)

        if playpause then
            if playing then
                icon.markup = "<span foreground='" .. color .. "'>" .. "" .. "</span>"
            else
                icon.markup = "<span foreground='" .. color .. "'>" .. "" .. "</span>"
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

-- Get Song Info
playerctl_daemon:connect_signal("metadata",
                       function(_, title, artist, album_path, album, new, player_name)

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
end)

playerctl_daemon:connect_signal("no_players", function(_)

    local title = "Nothing Playing"
    local artist = "Nothing Playing"
    local album_path = gears.filesystem.get_configuration_dir() .. "widget/playerctl/icons/default.png"

    -- Set art widget
    art:set_image(gears.surface.load_uncached(album_path))

    -- Set, title and artist widgets
    title_widget:set_markup_silently(
        '<span foreground="' .. beautiful.accent .. '">' .. title .. '</span>')
    artist_widget:set_markup_silently(
        '<span foreground="' .. beautiful.accent .. '">' .. artist .. '</span>')
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

local playerctl_play_symbol = create_button("", beautiful.fg_normal,
                                            play_command, true)

local playerctl_prev_symbol = create_button("玲", beautiful.fg_normal,
                                            prev_command, false)
local playerctl_next_symbol = create_button("怜", beautiful.fg_normal,
                                            next_command, false)

local slider = wibox.widget {
    forced_height = dpi(5),
    background_color = beautiful.background,
    color = beautiful.accent,
    value = 0,
    max_value = 100,
    forced_height = dpi(3),
    widget = wibox.widget.progressbar
}

playerctl_daemon:connect_signal(
    "position", function(_, interval_sec, length_sec, player_name)
        slider.value = (interval_sec / length_sec) * 100
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
                slider,
                top = dpi(10),
                left = dpi(25),
                right = dpi(25),
                widget = wibox.container.margin
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

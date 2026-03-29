local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/weather/icons/'
local clickable_container = require('widget.clickable-container')

local config = require('configuration.config')

local weather_cfg = config.widget.weather or {}
local open_weather_cfg = weather_cfg.open_weather or {}

if not open_weather_cfg.key and weather_cfg.key then
    open_weather_cfg.key = weather_cfg.key
end

if not open_weather_cfg.city_ids then
    if weather_cfg.city_ids then
        open_weather_cfg.city_ids = weather_cfg.city_ids
    elseif weather_cfg.city_id then
        open_weather_cfg.city_ids = { weather_cfg.city_id }
    else
        open_weather_cfg.city_ids = {}
    end
end

local secrets = {
    units = weather_cfg.units or 'metric',
    update_interval = weather_cfg.update_interval or 1200,
    providers = weather_cfg.providers or { 'open-meteo', 'wttr', 'open-weather' },
    locations = weather_cfg.locations or {},
    open_weather = open_weather_cfg,
}

if #secrets.locations == 0 then
    for _, city_id in ipairs(secrets.open_weather.city_ids) do
        table.insert(secrets.locations, {
            openweather_city_id = tostring(city_id),
            name = 'City ' .. tostring(city_id),
            wttr_query = tostring(city_id),
        })
    end
end

local weather_providers = {
    ['open-meteo'] = require('widget.weather.open-meteo'),
    ['wttr'] = require('widget.weather.wttr'),
    ['open-weather'] = require('widget.weather.open-weather'),
}

-- Constants for scrollable weather list
local WEATHER_HEIGHT = dpi(75)
local MAX_CITIES_VISIBLE = 2
local MAX_HEIGHT = WEATHER_HEIGHT * MAX_CITIES_VISIBLE + dpi(5)
local SCROLL_STEP = dpi(40)

-- Icon mapping
local icon_tbl = {
    ['01d'] = 'sun_icon.svg',
    ['01n'] = 'moon_icon.svg',
    ['02d'] = 'dfew_clouds.svg',
    ['02n'] = 'nfew_clouds.svg',
    ['03d'] = 'dscattered_clouds.svg',
    ['03n'] = 'nscattered_clouds.svg',
    ['04d'] = 'dbroken_clouds.svg',
    ['04n'] = 'nbroken_clouds.svg',
    ['09d'] = 'dshower_rain.svg',
    ['09n'] = 'nshower_rain.svg',
    ['10d'] = 'd_rain.svg',
    ['10n'] = 'n_rain.svg',
    ['11d'] = 'dthunderstorm.svg',
    ['11n'] = 'nthunderstorm.svg',
    ['13d'] = 'snow.svg',
    ['13n'] = 'snow.svg',
    ['50d'] = 'dmist.svg',
    ['50n'] = 'nmist.svg',
    ['...'] = 'weather-error.svg'
}

-- Return weather symbol
local get_weather_symbol = function()
    local symbol_tbl = {
        ['metric'] = '°C',
        ['imperial'] = '°F'
    }
    return symbol_tbl[secrets.units]
end

local function normalize_provider_name(name)
    if not name then
        return nil
    end

    local normalized = tostring(name):lower():gsub('_', '-')
    if normalized == 'openweather' then
        normalized = 'open-weather'
    elseif normalized == 'openmeteo' then
        normalized = 'open-meteo'
    end

    return normalized
end

local function get_fallback_providers()
    local ordered = {}

    for _, provider_name in ipairs(secrets.providers) do
        local normalized = normalize_provider_name(provider_name)
        if normalized and weather_providers[normalized] then
            table.insert(ordered, normalized)
        end
    end

    if #ordered == 0 then
        ordered = { 'open-meteo', 'wttr', 'open-weather' }
    end

    return ordered
end

local provider_order = get_fallback_providers()

local function get_location_label(location)
    return location.display_name or location.name or ('City ' .. tostring(location.openweather_city_id or '?'))
end

local function fetch_weather_with_fallback(location, callback)
    local function try_provider(index, last_error)
        if index > #provider_order then
            callback(false, nil, last_error)
            return
        end

        local provider_name = provider_order[index]
        local provider = weather_providers[provider_name]
        if not provider then
            try_provider(index + 1, last_error)
            return
        end

        if provider.is_available and not provider.is_available(location, secrets) then
            try_provider(index + 1, last_error)
            return
        end

        provider.fetch(location, secrets, function(ok, data, err)
            if ok and data then
                data.provider = provider_name
                callback(true, data, nil)
                return
            end

            try_provider(index + 1, err or last_error)
        end)
    end

    try_provider(1, nil)
end

local weather_header = wibox.widget {
    text   = 'Weather',
    font   = beautiful.font_bold(14),
    align  = 'left',
    valign = 'center',
    widget = wibox.widget.textbox
}

local header_time = wibox.widget {
    markup = '--:--',
    font   = beautiful.font_regular(10),
    align  = 'center',
    valign = 'center',
    widget = wibox.widget.textbox
}

local refresh_icon_widget = wibox.widget {
    image = widget_icon_dir .. 'refresh.svg',
    resize = true,
    forced_height = dpi(14),
    forced_width = dpi(14),
    widget = wibox.widget.imagebox,
}

local refresh_button = wibox.widget {
    {
        {
            refresh_icon_widget,
            margins = dpi(4),
            widget = wibox.container.margin,
        },
        widget = clickable_container,
    },
    bg = beautiful.accent,
    shape = gears.shape.circle,
    widget = wibox.container.background,
}

-- Layout for weather cards
local weather_list_layout = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(5),
}

-- Store weather card widgets for updating
local weather_cards = {}

local function create_weather_card(location)
    local weather_icon_widget = wibox.widget {
        id = 'icon',
        image = widget_icon_dir .. 'weather-error.svg',
        resize = true,
        forced_height = dpi(45),
        forced_width = dpi(45),
        widget = wibox.widget.imagebox,
    }

    local sunrise_icon = wibox.widget {
        image = widget_icon_dir .. 'sunrise.svg',
        resize = true,
        forced_height = dpi(18),
        forced_width = dpi(18),
        widget = wibox.widget.imagebox,
    }

    local sunset_icon = wibox.widget {
        image = widget_icon_dir .. 'sunset.svg',
        resize = true,
        forced_height = dpi(18),
        forced_width = dpi(18),
        widget = wibox.widget.imagebox,
    }

    local weather_location = wibox.widget {
        markup = 'Loading...',
        font = beautiful.font_regular(12),
        widget = wibox.widget.textbox
    }

    local weather_desc_temp = wibox.widget {
        markup = 'Fetching data...',
        font = beautiful.font_regular(12),
        widget = wibox.widget.textbox
    }

    local weather_sunrise = wibox.widget {
        markup = '00:00',
        font = beautiful.font_regular(12),
        widget = wibox.widget.textbox
    }

    local weather_sunset = wibox.widget {
        markup = '00:00',
        font = beautiful.font_regular(12),
        widget = wibox.widget.textbox
    }

    local weather_content = wibox.widget {
        layout = wibox.layout.align.horizontal,
        {
            -- Left: icon + location/description
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(10),
            {
                layout = wibox.layout.align.vertical,
                expand = 'none',
                nil,
                weather_icon_widget,
                nil
            },
            {
                layout = wibox.layout.align.vertical,
                expand = 'none',
                nil,
                {
                    layout = wibox.layout.fixed.vertical,
                    weather_location,
                    weather_desc_temp,
                },
                nil
            }
        },
        nil,
        {
            -- Right: sunrise/sunset stacked
            layout = wibox.layout.align.vertical,
            expand = 'none',
            nil,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(3),
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(3),
                    sunrise_icon,
                    weather_sunrise
                },
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(3),
                    sunset_icon,
                    weather_sunset
                }
            },
            nil
        }
    }

    local weather_card = wibox.widget {
        {
            -- Accent left border
            {
                forced_width = dpi(4),
                bg = beautiful.accent,
                widget = wibox.container.background,
            },
            -- Content area with inner background
            {
                {
                    {
                        weather_content,
                        margins = dpi(10),
                        widget = wibox.container.margin
                    },
                    bg = beautiful.background,
                    shape = function(cr, w, h)
                        gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
                    end,
                    widget = wibox.container.background,
                },
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
        forced_height = WEATHER_HEIGHT,
        widget = wibox.container.background,
    }

    return {
        card = weather_card,
        location = location,
        weather_icon = weather_icon_widget,
        weather_location = weather_location,
        weather_desc_temp = weather_desc_temp,
        weather_sunrise = weather_sunrise,
        weather_sunset = weather_sunset,
    }
end

for i, location in ipairs(secrets.locations) do
    weather_cards[i] = create_weather_card(location)
    weather_list_layout:add(weather_cards[i].card)
end

-- Scroll state
local scroll_offset = 0
local max_scroll = 0
local content_height = 0
local visible_height = MAX_HEIGHT

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
    weather_list_layout,
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
local function update_scrollbar()
    local child_count = #weather_list_layout.children
    content_height = child_count * WEATHER_HEIGHT + (child_count - 1) * dpi(5)

    -- Dynamic height: use content height up to MAX_HEIGHT
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

-- Set refreshing state for all cards
local function set_refreshing_state()
    for _, widget_set in ipairs(weather_cards) do
        widget_set.weather_desc_temp:set_markup('Refreshing...')
    end
end

-- Update a single weather card
local function update_weather_card(widget_set)
    fetch_weather_with_fallback(widget_set.location, function(ok, weather_data)
        if not ok or not weather_data then
            widget_set.weather_icon:set_image(widget_icon_dir .. 'weather-error.svg')
            widget_set.weather_location:set_markup(get_location_label(widget_set.location))
            widget_set.weather_desc_temp:set_markup('Failed to fetch')
            widget_set.weather_sunrise:set_markup('--:--')
            widget_set.weather_sunset:set_markup('--:--')
            return
        end

        local location = weather_data.location or get_location_label(widget_set.location)
        local country = weather_data.country
        local sunrise = weather_data.sunrise or '--:--'
        local sunset = weather_data.sunset or '--:--'
        local temp_number = tonumber(weather_data.temperature) or 0
        local temperature = math.floor(temp_number + 0.5)
        local weather_desc = weather_data.description or 'Unknown'
        local weather_icon_code = weather_data.icon_code or '...'

        local desc = weather_desc:sub(1, 1):upper() .. weather_desc:sub(2)
        local weather_description = desc .. ', ' .. temperature .. get_weather_symbol()
        local loc = country and (location .. ', ' .. country) or location

        local icon_file = icon_tbl[weather_icon_code] or 'weather-error.svg'
        widget_set.weather_icon:set_image(widget_icon_dir .. icon_file)
        widget_set.weather_location:set_markup(loc)
        widget_set.weather_desc_temp:set_markup(weather_description)
        widget_set.weather_sunrise:set_markup(sunrise)
        widget_set.weather_sunset:set_markup(sunset)

        header_time:set_markup(os.date('%H:%M'))
    end)
end

-- Update all weather cards
local function update_all_weather(show_refreshing)
    if show_refreshing then
        set_refreshing_state()
    end

    for _, widget_set in ipairs(weather_cards) do
        update_weather_card(widget_set)
    end
end

-- Refresh button handler
refresh_button:buttons(
    gears.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                update_all_weather(true)
            end
        )
    )
)

-- Main weather widget
local weather_report = wibox.widget {
    {
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(10),
            {
                layout = wibox.layout.align.horizontal,
                expand = 'none',
                weather_header,
                nil,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(8),
                    header_time,
                    refresh_button
                }
            },
            scroll_area
        },
        margins = dpi(10),
        widget = wibox.container.margin
    },
    bg = beautiful.groups_bg,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
    end,
    widget = wibox.container.background
}

-- Connect to existing signals for compatibility
awesome.connect_signal(
    'widget::weather_fetch',
    function()
        update_all_weather(false)
    end
)

-- Initial update
gears.timer.start_new(5, function()
    update_all_weather(false)
    update_scrollbar()
    return false
end)

-- Periodic update timer
gears.timer {
    timeout = secrets.update_interval,
    autostart = true,
    callback = function()
        update_all_weather(false)
    end
}

return weather_report

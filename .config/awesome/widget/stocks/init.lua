local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local gfs = gears.filesystem
local config = require('configuration.config')
local clickable_container = require('widget.clickable-container')

local config_dir = gfs.get_configuration_dir()
local fetcher_script = config_dir .. 'library/stocks/stocks_fetcher.sh'
local widget_icon_dir = config_dir .. 'widget/stocks/icons/'

-- Get stocks config
local stocks_config = config.widget.stocks or {}
local stocks_symbols = stocks_config.symbols or { 'NVDA' }
local update_interval = stocks_config.update_interval or 300

-- Constants for scrollable stock list
local STOCK_HEIGHT = dpi(60)
local MAX_STOCKS_VISIBLE = 2
local MAX_HEIGHT = STOCK_HEIGHT * MAX_STOCKS_VISIBLE + dpi(5) -- Exact height for 2 stocks + spacing
local SCROLL_STEP = dpi(40)

-- Create icon directory if needed
awful.spawn.easy_async_with_shell('mkdir -p ' .. widget_icon_dir, function() end)

local stocks_header = wibox.widget {
    text = 'Stocks',
    font = beautiful.font_bold(14),
    align = 'left',
    valign = 'center',
    widget = wibox.widget.textbox
}

-- Refresh button
local refresh_icon = wibox.widget {
    image = widget_icon_dir .. 'refresh.svg',
    resize = true,
    forced_height = dpi(14),
    forced_width = dpi(14),
    widget = wibox.widget.imagebox
}

local refresh_button = wibox.widget {
    {
        {
            refresh_icon,
            margins = dpi(4),
            widget = wibox.container.margin,
        },
        widget = clickable_container,
    },
    bg = beautiful.accent,
    shape = gears.shape.circle,
    widget = wibox.container.background,
}

-- Layout for stock items
local stock_list_layout = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(5),
}

-- Store stock card widgets for updating
local stock_cards = {}

-- Create a single stock card widget
local function create_stock_card(symbol)
    local symbol_widget = wibox.widget {
        markup = '<b>' .. symbol .. '</b>',
        font = beautiful.font_bold(11),
        widget = wibox.widget.textbox,
    }

    local price_widget = wibox.widget {
        text = 'Loading...',
        font = beautiful.font_mono(10),
        widget = wibox.widget.textbox,
    }

    local status_widget = wibox.widget {
        markup = '<span foreground="#888888">Fetching data...</span>',
        font = beautiful.font_regular(8),
        widget = wibox.widget.textbox,
    }

    local stock_content = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(2),
        {
            layout = wibox.layout.align.horizontal,
            symbol_widget,
            nil,
            price_widget,
        },
        status_widget,
    }

    local stock_template = wibox.widget {
        {
            stock_content,
            margins = dpi(10),
            widget = wibox.container.margin
        },
        bg = beautiful.background,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
        widget = wibox.container.background,
    }

    local card = wibox.widget {
        {
            -- Accent left border
            {
                forced_width = dpi(4),
                bg = beautiful.accent,
                widget = wibox.container.background,
            },
            -- Content area with inner background
            {
                stock_template,
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
        forced_height = STOCK_HEIGHT,
        widget = wibox.container.background,
    }

    return {
        card = card,
        symbol_widget = symbol_widget,
        price_widget = price_widget,
        status_widget = status_widget,
    }
end

-- Initialize stock cards
for i, symbol in ipairs(stocks_symbols) do
    stock_cards[i] = create_stock_card(symbol)
    stock_list_layout:add(stock_cards[i].card)
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
    stock_list_layout,
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
    local child_count = #stock_list_layout.children
    content_height = child_count * STOCK_HEIGHT + (child_count - 1) * dpi(5)

    -- Dynamic height: use content height up to MAX_HEIGHT
    visible_height = math.min(content_height, MAX_HEIGHT)
    scroll_clip.height = visible_height
    scrollbar_track.forced_height = visible_height

    max_scroll = math.max(0, content_height - MAX_HEIGHT)
    scroll_offset = math.max(0, math.min(scroll_offset, max_scroll))

    if max_scroll > 0 then
        scrollbar_track.visible = true
        local thumb_ratio = visible_height / content_height
        local thumb_height = math.max(
            dpi(20), math.min(visible_height - dpi(10),
                visible_height * thumb_ratio))
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

-- Simple JSON parser for Lua
local function parse_json(json_string)
    json_string = json_string:gsub('^%s+', ''):gsub('%s+$', '')

    if not json_string:match('^%{') then
        return nil, "Not valid JSON object"
    end

    local result = {}

    -- Extract string fields
    local symbol_match = json_string:match('"symbol"%s*:%s*"([^"]+)"')
    local status_match = json_string:match('"status"%s*:%s*"([^"]+)"')
    local error_match = json_string:match('"error"%s*:%s*"([^"]+)"')

    -- Extract numeric fields
    local price_match = json_string:match('"price"%s*:%s*([%d.]+)')
    local change_match = json_string:match('"change"%s*:%s*([-]?[%d.]+)')
    local change_pct_match = json_string:match('"change_percent"%s*:%s*([-]?[%d.]+)')
    local premarket_match = json_string:match('"premarket"%s*:%s*([%d.]+)')
    local postmarket_match = json_string:match('"postmarket"%s*:%s*([%d.]+)')

    if error_match then
        return { error = error_match, symbol = symbol_match }
    end

    result.symbol = symbol_match or "UNKNOWN"
    result.price = price_match and tonumber(price_match) or nil
    result.change = change_match and tonumber(change_match) or 0
    result.change_percent = change_pct_match and tonumber(change_pct_match) or 0
    result.status = status_match or "Unknown"
    result.premarket = premarket_match and tonumber(premarket_match) or nil
    result.postmarket = postmarket_match and tonumber(postmarket_match) or nil

    return result
end

local set_refreshing_state = function()
    for i, _ in ipairs(stocks_symbols) do
        local widget_set = stock_cards[i]
        if widget_set then
            widget_set.price_widget:set_markup(
                '<span foreground="' .. beautiful.fg_normal ..
                '">Refreshing...</span>')
        end
    end
end

local update_stocks = function(show_refreshing)
    if show_refreshing then
        set_refreshing_state()
    end

    for i, symbol in ipairs(stocks_symbols) do
        local cmd = 'bash ' .. fetcher_script .. ' ' .. symbol

        awful.spawn.easy_async_with_shell(
            cmd,
            function(stdout, stderr)
                local widget_set = stock_cards[i]
                if not widget_set then return end

                if not stdout or stdout == "" then
                    widget_set.price_widget:set_text("Error")
                    widget_set.status_widget:set_markup(
                        '<span foreground="' ..
                        beautiful.colors.red .. '">' ..
                        (stderr or "Unknown error") .. '</span>')
                    return
                end

                local data = parse_json(stdout)

                if not data or data.error then
                    widget_set.price_widget:set_text("Error")
                    widget_set.status_widget:set_markup(
                        '<span foreground="' ..
                        beautiful.colors.red .. '">' ..
                        (data and data.error or "Parse failed") .. '</span>')
                    return
                end

                local price = data.price
                local change = data.change
                local change_pct = data.change_percent
                local status = data.status

                -- Format price display
                local price_str = ""
                local change_color = beautiful.fg_normal
                if price and price > 0 then
                    local abs_change = math.abs(change)
                    local abs_pct = math.abs(change_pct)

                    if change >= 0 then
                        price_str = string.format(
                            "$%.2f  ↑ +%.2f (+%.2f%%)",
                            price, abs_change, abs_pct)
                        change_color = beautiful.colors.green
                    else
                        price_str = string.format(
                            "$%.2f  ↓ -%.2f (-%.2f%%)",
                            price, abs_change, abs_pct)
                        change_color = beautiful.colors.red
                    end
                else
                    price_str = "N/A"
                end

                -- Add extended hours info
                local extended_info = ""
                if data.premarket and data.premarket > 0 then
                    extended_info = string.format(" | Pre: $%.2f", data.premarket)
                end
                if data.postmarket and data.postmarket > 0 then
                    extended_info = extended_info .. string.format(" | Post: $%.2f", data.postmarket)
                end

                widget_set.price_widget:set_markup(
                    '<span foreground="' .. change_color .. '">' ..
                    price_str .. '</span>')

                widget_set.status_widget:set_markup(
                    '<span foreground="' ..
                    beautiful.fg_normal .. '">' .. status ..
                    extended_info .. '</span>')
            end
        )
    end
end

-- Initial update
gears.timer.delayed_call(function()
    update_stocks()
    update_scrollbar()
end)

-- Update timer
gears.timer {
    timeout = update_interval,
    autostart = true,
    callback = function()
        update_stocks()
    end
}

-- Refresh button click handler
refresh_button:buttons(
    gears.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                update_stocks(true) -- Show refreshing state
            end
        )
    )
)

-- Main stocks widget
local stocksbox = wibox.widget {
    {
        {
            -- Header row
            {
                layout = wibox.layout.align.horizontal,
                expand = 'none',
                stocks_header,
                nil,
                refresh_button
            },
            -- Spacing
            {
                forced_height = dpi(10),
                widget = wibox.container.background,
            },
            -- Stock list
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

awesome.connect_signal(
    'widget::update_stocks',
    function()
        update_stocks()
    end
)

return stocksbox

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

-- Create icon directory if needed
awful.spawn.easy_async_with_shell('mkdir -p ' .. widget_icon_dir, function() end)

local stocks_title = wibox.widget {
    font = beautiful.font_bold(16),
    markup = 'Stocks',
    widget = wibox.widget.textbox
}

-- Create stock display widgets dynamically
local stock_widgets = {}
for i, symbol in ipairs(stocks_symbols) do
    stock_widgets[i] = {
        symbol_widget = wibox.widget {
            markup = symbol,
            font = beautiful.font_regular(10),
            align = 'left',
            valign = 'center',
            widget = wibox.widget.textbox
        },
        price_widget = wibox.widget {
            font = beautiful.font_mono(10),
            align = 'left',
            valign = 'center',
            widget = wibox.widget.textbox
        },
        status_widget = wibox.widget {
            font = beautiful.font_regular(8),
            align = 'left',
            valign = 'center',
            widget = wibox.widget.textbox
        }
    }
end

-- Refresh button
local refresh_icon = wibox.widget {
    image = widget_icon_dir .. 'refresh.svg',
    resize = true,
    forced_height = dpi(20),
    forced_width = dpi(20),
    widget = wibox.widget.imagebox
}

local refresh_button = clickable_container(refresh_icon)

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

local update_stocks = function()
    for i, symbol in ipairs(stocks_symbols) do
        local cmd = 'bash ' .. fetcher_script .. ' ' .. symbol

        awful.spawn.easy_async_with_shell(
            cmd,
            function(stdout, stderr)
                local widget_set = stock_widgets[i]

                if not stdout or stdout == "" then
                    widget_set.price_widget:set_text("Error: No output")
                    widget_set.status_widget:set_text(stderr or "Unknown error")
                    return
                end

                local data = parse_json(stdout)

                if not data or data.error then
                    widget_set.price_widget:set_text("Error: " .. (data and data.error or "Parse failed"))
                    widget_set.status_widget:set_text("")
                    return
                end

                local price = data.price
                local change = data.change
                local change_pct = data.change_percent
                local status = data.status

                -- Format price display with alignment
                local price_str = ""
                if price and price > 0 then
                    -- Use absolute values and add signs explicitly for proper alignment
                    local abs_change = math.abs(change)
                    local abs_pct = math.abs(change_pct)

                    if change >= 0 then
                        price_str = string.format("$%7.2f  ↑  +%6.2f  (+%5.2f%%)", price, abs_change, abs_pct)
                    else
                        price_str = string.format("$%7.2f  ↓  -%6.2f  (-%5.2f%%)", price, abs_change, abs_pct)
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

                widget_set.price_widget:set_text(price_str)
                widget_set.status_widget:set_text(status .. extended_info)
            end
        )
    end
end

-- Initial update
gears.timer.delayed_call(function()
    update_stocks()
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
                update_stocks()
            end
        )
    )
)

-- Build stock entries layout
local stock_entries = wibox.layout.fixed.vertical()
stock_entries.spacing = dpi(8)

for i, _ in ipairs(stocks_symbols) do
    local widget_set = stock_widgets[i]
    local entry = wibox.widget {
        expand = 'none',
        {
            expand = 'none',
            layout = wibox.layout.align.horizontal,
            forced_height = dpi(15),
            {
                layout = wibox.layout.fixed.horizontal,
                widget_set.symbol_widget,
            },
            nil,
            {
                widget_set.price_widget,
                layout = wibox.layout.fixed.horizontal
            }
        },
        {
            expand = 'none',
            layout = wibox.layout.align.horizontal,
            forced_height = dpi(12),
            {
                widget_set.status_widget,
                layout = wibox.layout.fixed.horizontal
            }
        },
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(3)
    }
    stock_entries:add(entry)
end

-- Build stocks template with refresh button
local stocks_template = wibox.widget {
    expand = 'none',
    {
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            stock_entries,
        },
        margins = dpi(10),
        widget = wibox.container.margin
    },
    margins = dpi(10),
    bg = beautiful.background,
    shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
    end,
    widget = wibox.container.background
}

-- Put the generated template to a container
local stocksbox = wibox.widget {
    {
        {
            expand = 'none',
            layout = wibox.layout.fixed.vertical,
            {
                layout = wibox.layout.align.horizontal,
                stocks_title,
                nil,
                refresh_button
            },
            stocks_template,
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

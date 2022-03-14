local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local naughty = require('naughty')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi

local config = require('configuration.api_keys')
local secrets = {
    api_key = config.widget.stocks.api_key
}

local stocks = wibox.widget {
    font = 'Hack Nerd Bold 16',
    markup = 'Stocks',
    widget = wibox.widget.textbox
}

local symbol = wibox.widget {
    markup = 'NVDA',
    font   = 'Hack Nerd Regular 10',
    align  = 'left',
    valign = 'center',
    widget = wibox.widget.textbox
}

local stock_price = wibox.widget {
    font   = 'Hack Nerd Regular 10',
    align  = 'left',
    valign = 'center',
    widget = wibox.widget.textbox
}


local stocks_to_fetch = {
    'NVDA'
}

local update_stocks = function()
    local fetch_stock_price_command = " "

    for i, stock in ipairs(stocks_to_fetch) do

        --naughty.notify({text = stock})

        fetch_stock_price_command = [[
            curl --silent \
            https://www.alphavantage.co/query\?function\=GLOBAL_QUOTE\&symbol\=]] .. stock .. [[\&apikey\=]] .. secrets.api_key .. [[ | \
            python3 -c 'import sys, json; print(json.load(sys.stdin)["Global Quote"]["05. price"])'
        ]]


        awful.spawn.easy_async_with_shell(
            fetch_stock_price_command,
            function(stdout)
                --naughty.notify({text = tostring(stdout)})
                stock_price:set_text(tostring(stdout))
            end
        )

    end
end

-- Update on startup
update_stocks()

local stocks_template =  wibox.widget {
    expand = 'none',
    {
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            {
                expand = 'none',
                layout = wibox.layout.align.horizontal,
                forced_height = dpi(15),
                {
                    layout = wibox.layout.fixed.horizontal,
                    symbol,
                },
                nil,
                {
                    stock_price,
                    layout = wibox.layout.fixed.horizontal
                }
            },
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
            stocks,
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

stock_price:emit_signal('widget::redraw_needed')
return stocksbox

local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local naughty = require('naughty')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi

local clickable_container = require('widget.clickable-container')
local apps = require('configuration.apps')

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
    markup = 'N/A',
    font   = 'Hack Nerd Regular 10',
    align  = 'left',
    valign = 'center',
    widget = wibox.widget.textbox
}

local stocks_to_fetch = {
    'nvda'
}

local update_stocks = function()
    local fetch_stock_price_command = " "

    for i, stock in ipairs(stocks_to_fetch) do

        fetch_stock_price_command = [[
            curl -L stonks.icu/]] .. stock .. [[ | grep -oP '.{0,7}USD'
        ]]

        awful.spawn.easy_async_with_shell(
            fetch_stock_price_command,
            function(stdout)
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

gears.timer {
	timeout = 120,
	autostart = true,
	callback  = function()
		update_stocks()
	end
}

local stocks_button = wibox.widget {
	{
		stocksbox,
		margins = dpi(7),
		widget = wibox.container.margin
	},
	widget = clickable_container
}

stocks_button:buttons(
	gears.table.join(
		awful.button(
			{},
			1,
			nil,
			function()
			    local focused = awful.screen.focused()
			    if focused.info_center and focused.info_center.visible then
			    	focused.info_center:toggle()
			    end
                awful.spawn(apps.default.terminal ..
                    ' --class stocks --hold -o font.size=8 -e /bin/zsh \
                    -c "curl -s -L stonks.icu/nvda | head -n -3"')
			end
		)
	)
)

stock_price:emit_signal('widget::redraw_needed')

return stocks_button

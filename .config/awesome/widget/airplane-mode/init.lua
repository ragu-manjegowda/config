local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local config_dir = gears.filesystem.get_configuration_dir()
local widget_dir = config_dir .. 'widget/airplane-mode/'
local widget_icon_dir = widget_dir .. 'icons/'
local ap_state = false

local action_name = wibox.widget {
    text = 'Airplane Mode',
    font = 'Hack Nerd Bold 12',
    align = 'left',
    widget = wibox.widget.textbox
}

local action_status = wibox.widget {
    text = 'Off',
    font = 'Hack Nerd Regular 12',
    align = 'left',
    widget = wibox.widget.textbox
}

local action_info = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    action_name,
    action_status
}

local button_widget = wibox.widget {
    {
        id = 'icon',
        image = widget_icon_dir .. 'airplane-mode-off.svg',
        widget = wibox.widget.imagebox,
        resize = true
    },
    layout = wibox.layout.align.horizontal
}

local widget_button = wibox.widget {
    {
        {
            button_widget,
            margins = dpi(15),
            forced_height = dpi(48),
            forced_width = dpi(48),
            widget = wibox.container.margin
        },
        widget = clickable_container
    },
    bg = beautiful.groups_bg,
    shape = gears.shape.circle,
    widget = wibox.container.background
}

local update_widget = function()
    if ap_state then
        action_status:set_text('On')
        widget_button.bg = beautiful.accent
        button_widget.icon:set_image(widget_icon_dir .. 'airplane-mode.svg')
    else
        action_status:set_text('Off')
        widget_button.bg = beautiful.groups_bg
        button_widget.icon:set_image(widget_icon_dir .. 'airplane-mode-off.svg')
    end
end

local ap_off_cmd = [[

	rfkill unblock wlan

	# Create an AwesomeWM Notification
	awesome-client "
	naughty = require('naughty')
	naughty.notification({
		app_name = 'Network Manager',
		title = '<b>Airplane mode disabled!</b>',
		message = 'Initializing network devices',
		icon = ']] .. widget_icon_dir .. 'airplane-mode-off' .. '.svg' .. [['
	})
	"
	]] .. "echo false > " .. widget_dir .. "airplane_mode" .. [[
]]

local ap_on_cmd = [[

	rfkill block wlan

	# Create an AwesomeWM Notification
	awesome-client "
	naughty = require('naughty')
	naughty.notification({
		app_name = 'Network Manager',
		title = '<b>Airplane mode enabled!</b>',
		message = 'Disabling radio devices',
		icon = ']] .. widget_icon_dir .. 'airplane-mode' .. '.svg' .. [['
	})
	"
	]] .. 'echo true > ' .. widget_dir .. 'airplane_mode' .. [[
]]

local toggle_action = function()
    if ap_state then
        awful.spawn.easy_async_with_shell(
            ap_off_cmd,
            function(_)
                ap_state = false
                update_widget()
            end
        )
    else
        awful.spawn.easy_async_with_shell(
            ap_on_cmd,
            function(_)
                ap_state = true
                update_widget()
            end
        )
    end
end

widget_button:buttons(
    gears.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                toggle_action()
            end
        )
    )
)

action_info:buttons(
    gears.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                toggle_action()
            end
        )
    )
)

local action_widget = wibox.widget {
    layout = wibox.layout.fixed.horizontal,
    spacing = dpi(10),
    widget_button,
    {
        layout = wibox.layout.align.vertical,
        expand = 'none',
        nil,
        action_info,
        nil
    }

}

return action_widget

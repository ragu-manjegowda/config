local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local config_dir = gears.filesystem.get_configuration_dir()
local widget_dir = config_dir .. 'widget/blue-light/'
local widget_icon_dir = widget_dir .. 'icons/'

local action_name = wibox.widget {
    text = 'Blue Light',
    font = beautiful.font_bold(11),
    align = 'left',
    widget = wibox.widget.textbox
}

local action_status = wibox.widget {
    text = 'Off',
    font = beautiful.font_regular(10),
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
        image = widget_icon_dir .. 'blue-light-off.svg',
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
    bg = beautiful.background,
    shape = gears.shape.circle,
    widget = wibox.container.background
}

local blue_light_state = false

local update_widget = function()
    if blue_light_state then
        action_status:set_text('On')
        widget_button.bg = beautiful.accent
        button_widget.icon:set_image(widget_icon_dir .. 'blue-light.svg')
    else
        action_status:set_text('Off')
        widget_button.bg = beautiful.background
        button_widget.icon:set_image(widget_icon_dir .. 'blue-light-off.svg')
    end
end

local filter_busy = false
local pending_action
local run_filter
run_filter = function(action)
    if filter_busy then
        pending_action = action
        return
    end
    filter_busy = true
    awful.spawn.easy_async({ '/bin/bash', config_dir .. 'utilities/display/blue-light', action },
        function(stdout, _, _, exit_code)
            filter_busy = false
            blue_light_state = exit_code == 0 and stdout:match('ON') ~= nil
            update_widget()
            if pending_action then
                local next_action = pending_action
                pending_action = nil
                run_filter(next_action)
            end
        end)
end

local toggle_action = function() run_filter('toggle') end
local refresh_pending = false
local refresh_filter = function()
    if refresh_pending then return end
    refresh_pending = true
    gears.timer.delayed_call(function()
        refresh_pending = false
        run_filter('refresh')
    end)
end
screen.connect_signal('added', refresh_filter)
screen.connect_signal('removed', refresh_filter)
screen.connect_signal('property::geometry', refresh_filter)
local wake_refresh = function()
    gears.timer.start_new(1, function()
        refresh_filter()
        return false
    end)
end
awesome.connect_signal('module::unlocked', wake_refresh)
awesome.connect_signal('module::sleep_resumed', wake_refresh)
run_filter('start')

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

awesome.connect_signal(
    'widget::blue_light:toggle',
    function()
        toggle_action()
    end
)

return action_widget

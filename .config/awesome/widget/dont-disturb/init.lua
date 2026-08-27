local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local naughty = require('naughty')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local suspension = require('library.notification-suspension')
local lifecycle = require('library.notification-lifecycle')
local config_dir = gears.filesystem.get_configuration_dir()
local widget_dir = config_dir .. 'widget/dont-disturb/'
local widget_icon_dir = widget_dir .. 'icons/'
local sound_handled = setmetatable({}, { __mode = 'k' })

_G.dont_disturb_state = false

local action_name = wibox.widget {
    text = 'Don\'t Disturb',
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
        image = widget_icon_dir .. 'notify.svg',
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
    if _G.dont_disturb_state then
        action_status:set_text('On')
        widget_button.bg = beautiful.accent
        button_widget.icon:set_image(widget_icon_dir .. 'dont-disturb.svg')
    else
        action_status:set_text('Off')
        widget_button.bg = beautiful.groups_bg
        button_widget.icon:set_image(widget_icon_dir .. 'notify.svg')
    end
end

local check_disturb_status = function()
    local input = io.open(widget_dir .. 'disturb_status', 'r')
    local status = input and input:read('*l') or 'false'
    if input then
        input:close()
    end
    _G.dont_disturb_state = status == 'true'
    suspension.set('dnd', _G.dont_disturb_state)
    update_widget()
end

check_disturb_status()

local set_disturb_status = function(enabled)
    _G.dont_disturb_state = enabled
    suspension.set('dnd', enabled)
    local output = io.open(widget_dir .. 'disturb_status', 'w')
    if output then
        output:write(tostring(enabled))
        output:close()
    end
    update_widget()
end

local toggle_action = function()
    set_disturb_status(not dont_disturb_state)
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

-- Create a notification sound
naughty.connect_signal(
    'property::active',
    function()
        local n = naughty.active[#naughty.active]
        if lifecycle.should_play_sound(n, sound_handled, dont_disturb_state) then
            awful.spawn.with_shell('canberra-gtk-play -i message 2>/dev/null')
        end
    end
)

awesome.connect_signal(
    'widget::dont_disturb:set',
    function(enabled)
        set_disturb_status(enabled)
    end
)

return action_widget

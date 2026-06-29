local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local icons = require('theme.icons')

local presentation_enabled = false
local previous_dont_disturb_state = false
local previous_blur_state = true

local action_name = wibox.widget {
    text = 'Presentation',
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
        image = icons.toggled_off,
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
    if presentation_enabled then
        action_status:set_text('On')
        widget_button.bg = beautiful.accent
        button_widget.icon:set_image(icons.toggled_on)
    else
        action_status:set_text('Off')
        widget_button.bg = beautiful.groups_bg
        button_widget.icon:set_image(icons.toggled_off)
    end
end

local set_presentation_mode = function(enabled)
    if presentation_enabled == enabled then
        update_widget()
        return
    end

    if enabled then
        previous_dont_disturb_state = _G.dont_disturb_state == true
        previous_blur_state = _G.blur_effects_state ~= false
        awesome.emit_signal('widget::dont_disturb:set', true)
        awesome.emit_signal('widget::blur:set', false)
    else
        awesome.emit_signal('widget::dont_disturb:set', previous_dont_disturb_state)
        awesome.emit_signal('widget::blur:set', previous_blur_state)
    end

    presentation_enabled = enabled
    update_widget()
end

local toggle_presentation_mode = function()
    set_presentation_mode(not presentation_enabled)
end

widget_button:buttons(
    gears.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                toggle_presentation_mode()
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
                toggle_presentation_mode()
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
    'widget::presentation_mode:set',
    function(enabled)
        set_presentation_mode(enabled)
    end
)

awesome.connect_signal(
    'widget::presentation_mode:toggle',
    function()
        toggle_presentation_mode()
    end
)

return action_widget

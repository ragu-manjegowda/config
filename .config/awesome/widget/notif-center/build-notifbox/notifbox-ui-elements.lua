local symbolic = require('theme.symbolic')
local notification_icon = require('widget.notification-icon')
local bindings = require('theme.bindings')
local wibox = require('wibox')
local beautiful = require('beautiful')
local naughty = require('naughty')
local gears = require('gears')

local dpi = beautiful.xresources.apply_dpi

local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/notif-center/icons/'

local clickable_container = require('widget.clickable-container')

local ui_noti_builder = {}
local TITLE_MAX_HEIGHT = dpi(24)
local MESSAGE_MAX_HEIGHT = dpi(40)

local function bounded_textbox(text, font, max_height)
    local textbox = wibox.widget {
        markup = gears.string.xml_escape(text or ''),
        font = font,
        align = 'left',
        valign = 'top',
        wrap = 'word_char',
        ellipsize = 'end',
        widget = wibox.widget.textbox,
    }

    return wibox.widget {
        textbox,
        strategy = 'max',
        height = max_height,
        widget = wibox.container.constraint,
    }
end

-- Notification icon container
ui_noti_builder.notifbox_icon = function(ico_image)
    local path = notification_icon.source(ico_image)
    local noti_icon = wibox.widget {
        {
            id = 'icon',
            resize = true,
            forced_height = dpi(25),
            forced_width = dpi(25),
            widget = path and symbolic.imagebox or wibox.widget.imagebox
        },
        layout = wibox.layout.fixed.horizontal
    }
    noti_icon.icon:set_image(path or ico_image)
    return noti_icon
end

-- Notification title container
ui_noti_builder.notifbox_title = function(title)
    return bounded_textbox(title, beautiful.font_bold(8), TITLE_MAX_HEIGHT)
end

-- Notification message container
ui_noti_builder.notifbox_message = function(msg)
    return bounded_textbox(msg, beautiful.font_regular(6), MESSAGE_MAX_HEIGHT)
end

-- Notification app name container
ui_noti_builder.notifbox_appname = function(app)
    return wibox.widget {
        markup = gears.string.xml_escape(app),
        font   = beautiful.font_bold(10),
        align  = 'left',
        valign = 'center',
        widget = wibox.widget.textbox
    }
end

-- Notification actions container
ui_noti_builder.notifbox_actions = function(n)
    local actions_template = wibox.widget {
        notification = n,
        base_layout = wibox.widget {
            spacing = dpi(0),
            layout  = wibox.layout.flex.horizontal
        },
        widget_template = {
            {
                {
                    {
                        {
                            id     = 'text_role',
                            font   = beautiful.font_regular(10),
                            widget = wibox.widget.textbox
                        },
                        widget = wibox.container.place
                    },
                    widget = clickable_container
                },
                shape         = gears.shape.rounded_rect,
                forced_height = 30,
                widget        = bindings.widget(wibox.container.background, { bg = 'groups_bg' })
            },
            margins = 4,
            widget  = wibox.container.margin
        },
        style = { underline_normal = false, underline_selected = true },
        widget = naughty.list.actions,
    }

    return actions_template
end


-- Notification dismiss button
ui_noti_builder.notifbox_dismiss = function()
    local dismiss_imagebox = wibox.widget {
        {
            id = 'dismiss_icon',
            image = widget_icon_dir .. 'delete.svg',
            resize = true,
            forced_height = dpi(5),
            widget = symbolic.imagebox
        },
        layout = wibox.layout.fixed.horizontal
    }

    local dismiss_button = wibox.widget {
        {
            dismiss_imagebox,
            margins = dpi(5),
            widget = wibox.container.margin
        },
        widget = clickable_container
    }

    local notifbox_dismiss = wibox.widget {
        dismiss_button,
        visible = false,
        shape = gears.shape.circle,
        widget = bindings.widget(wibox.container.background, { bg = 'accent' })
    }

    -- Change background on hover
    notifbox_dismiss:connect_signal('mouse::enter', function()
        bindings.bind(notifbox_dismiss, { bg = 'groups_title_bg' })
    end)

    notifbox_dismiss:connect_signal('mouse::leave', function()
        bindings.bind(notifbox_dismiss, { bg = 'accent' })
    end)

    return notifbox_dismiss
end


return ui_noti_builder

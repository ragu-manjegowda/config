local gears = require('gears')
local wibox = require('wibox')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local recorder_icons = require('widget.screen-recorder.screen-recorder-icons')
local record_tbl = {}

local function accent_hover(widget)
    widget:connect_signal('mouse::enter', function()
        widget.shape_border_width = dpi(2)
        widget.shape_border_color = beautiful.accent
    end)
    widget:connect_signal('mouse::leave', function()
        widget.shape_border_width = dpi(0)
        widget.shape_border_color = beautiful.transparent
    end)
end

-- Panel UI
record_tbl.screen_rec_toggle_imgbox = wibox.widget {
    image = recorder_icons.normal('start-recording-button'),
    resize = true,
    widget = wibox.widget.imagebox
}

record_tbl.screen_rec_toggle_button = wibox.widget {
    {
        record_tbl.screen_rec_toggle_imgbox,
        margins = dpi(7),
        widget = wibox.container.margin
    },
    widget = clickable_container
}

record_tbl.screen_rec_countdown_txt = wibox.widget {
    id = 'countdown_text',
    font = beautiful.font_bold(64),
    text = '4',
    align = 'center',
    valign = 'bottom',
    opacity = 0.0,
    widget = wibox.widget.textbox
}

record_tbl.screen_rec_main_imgbox = wibox.widget {
    image = recorder_icons.normal('recorder-off'),
    resize = true,
    widget = wibox.widget.imagebox
}

record_tbl.screen_rec_main_button = wibox.widget {
    {
        {
            {
                record_tbl.screen_rec_main_imgbox,
                margins = dpi(24),
                widget = wibox.container.margin
            },
            widget = clickable_container
        },
        forced_width = dpi(200),
        forced_height = dpi(200),
        bg = beautiful.groups_bg,
        shape = gears.shape.circle,
        widget = wibox.container.background
    },
    margins = dpi(24),
    widget = wibox.container.margin
}

record_tbl.screen_rec_audio_imgbox = wibox.widget {
    image = recorder_icons.normal('audio'),
    resize = true,
    widget = wibox.widget.imagebox
}

record_tbl.screen_rec_audio_button = wibox.widget {
    {
        nil,
        {
            {
                record_tbl.screen_rec_audio_imgbox,
                margins = dpi(16),
                widget = wibox.container.margin
            },
            widget = clickable_container
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    },
    forced_width = dpi(60),
    forced_height = dpi(60),
    bg = beautiful.groups_bg,
    shape = gears.shape.circle,
    widget = wibox.container.background
}

record_tbl.screen_rec_close_imgbox = wibox.widget {
    image = recorder_icons.normal('close-screen'),
    resize = true,
    widget = wibox.widget.imagebox
}

record_tbl.screen_rec_close_button = wibox.widget {
    {
        nil,
        {
            {
                record_tbl.screen_rec_close_imgbox,
                margins = dpi(16),
                widget = wibox.container.margin
            },
            widget = clickable_container
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.horizontal
    },
    forced_width = dpi(60),
    forced_height = dpi(60),
    bg = beautiful.groups_bg,
    shape = gears.shape.circle,
    widget = wibox.container.background
}

record_tbl.screen_rec_settings_imgbox = wibox.widget {
    image = recorder_icons.normal('settings'),
    resize = true,
    widget = wibox.widget.imagebox
}

record_tbl.screen_rec_settings_button = wibox.widget {
    id = 'recorder_settings_button',
    {
        nil,
        {
            {
                record_tbl.screen_rec_settings_imgbox,
                margins = dpi(16),
                widget = wibox.container.margin
            },
            widget = clickable_container
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    },
    forced_width = dpi(60),
    forced_height = dpi(60),
    bg = beautiful.groups_bg,
    shape = gears.shape.circle,
    widget = wibox.container.background
}

record_tbl.screen_rec_back_imgbox = wibox.widget {
    image = recorder_icons.normal('back'),
    resize = true,
    widget = wibox.widget.imagebox
}

record_tbl.screen_rec_back_button = wibox.widget {
    {
        nil,
        {
            {
                record_tbl.screen_rec_back_imgbox,
                margins = dpi(16),
                widget = wibox.container.margin
            },
            widget = clickable_container
        },
        nil,
        expand = 'none',
        layout = wibox.layout.align.vertical
    },
    forced_width = dpi(48),
    forced_height = dpi(48),
    bg = beautiful.groups_bg,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
    end,
    widget = wibox.container.background
}

accent_hover(record_tbl.screen_rec_main_button:get_children()[1])
accent_hover(record_tbl.screen_rec_settings_button)
accent_hover(record_tbl.screen_rec_audio_button)
accent_hover(record_tbl.screen_rec_close_button)
accent_hover(record_tbl.screen_rec_back_button)

record_tbl.screen_rec_back_txt = wibox.widget {
    {
        text = 'Back',
        font = beautiful.font_bold(16),
        align = 'left',
        valign = 'center',
        widget = wibox.widget.textbox
    },
    margins = dpi(5),
    widget = wibox.container.margin

}

record_tbl.screen_rec_source_txt = wibox.widget {
    {
        text = 'Capture source',
        font = beautiful.font_bold(16),
        align = 'left',
        valign = 'center',
        widget = wibox.widget.textbox
    },
    margins = dpi(5),
    widget = wibox.container.margin

}

local function source_button(id, label)
    local button = wibox.widget {
        id = id .. '_button',
        {
            {
                id = id .. '_label',
                text = label,
                font = beautiful.font_bold(16),
                align = 'center',
                valign = 'center',
                widget = wibox.widget.textbox
            },
            margins = dpi(8),
            widget = wibox.container.margin
        },
        forced_width = dpi(150),
        forced_height = dpi(44),
        bg = beautiful.groups_bg,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
        end,
        widget = wibox.container.background
    }
    local old_cursor, old_wibox
    button:connect_signal('mouse::enter', function()
        if button.available ~= false then
            button.shape_border_width = dpi(2)
            button.shape_border_color = beautiful.accent
            local active_wibox = mouse.current_wibox
            if active_wibox then
                old_cursor, old_wibox = active_wibox.cursor, active_wibox
                active_wibox.cursor = 'hand1'
            end
        end
    end)
    button:connect_signal('mouse::leave', function()
        button.shape_border_width = button.selected and dpi(2) or dpi(0)
        button.shape_border_color = button.selected and beautiful.accent or beautiful.transparent
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)
    button:connect_signal('button::press', function()
        if button.available ~= false then button.bg = beautiful.press_event end
    end)
    button:connect_signal('button::release', function()
        button.bg = beautiful.groups_bg
    end)
    return button
end

record_tbl.screen_rec_source_buttons = {
    primary = source_button('primary_source', 'Primary'),
    external = source_button('external_source', 'External'),
    both = source_button('both_source', 'Both'),
    region = source_button('region_source', 'Select area')
}

record_tbl.screen_rec_source_rows = wibox.widget {
    {
        record_tbl.screen_rec_source_buttons.primary,
        record_tbl.screen_rec_source_buttons.external,
        spacing = dpi(8),
        layout = wibox.layout.fixed.horizontal
    },
    {
        record_tbl.screen_rec_source_buttons.both,
        record_tbl.screen_rec_source_buttons.region,
        spacing = dpi(8),
        layout = wibox.layout.fixed.horizontal
    },
    spacing = dpi(8),
    layout = wibox.layout.fixed.vertical
}

record_tbl.screen_rec_area_txt = wibox.widget {
    {
        text = 'Area',
        font = beautiful.font_bold(16),
        align = 'left',
        valign = 'center',
        widget = wibox.widget.textbox
    },
    margins = dpi(5),
    widget = wibox.container.margin
}

record_tbl.screen_rec_area_txtbox = wibox.widget {
    {
        id = 'area_tbox',
        text = 'Resolving display geometry...',
        font = beautiful.font_regular(16),
        align = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    },
    margins = dpi(10),
    forced_width = dpi(308),
    forced_height = dpi(44),
    bg = beautiful.groups_bg,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
    end,
    widget = wibox.container.background
}

record_tbl.screen_rec_area_hint = wibox.widget {
    {
        id = 'source_keys_tbox',
        text = '1 Primary · 2 External · 3 Both · 4 Area',
        font = beautiful.font_regular(12),
        align = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    },
    {
        id = 'cancel_hint_tbox',
        text = 'Esc returns to recorder',
        font = beautiful.font_regular(12),
        align = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    },
    spacing = dpi(3),
    layout = wibox.layout.fixed.vertical,
    top = dpi(4),
    left = dpi(4),
    right = dpi(4),
    widget = wibox.container.margin
}

screen.connect_signal("request::desktop_decoration", function(s)
    s.recorder_settings_button = record_tbl.screen_rec_settings_button
    s.recorder_source_buttons = record_tbl.screen_rec_source_buttons
    s.recorder_main_button = record_tbl.screen_rec_main_button
    s.recorder_close_button = record_tbl.screen_rec_close_button
    s.recorder_countdown_text = record_tbl.screen_rec_countdown_txt
    s.recorder_screen = wibox(
        {
            ontop = true,
            screen = s,
            type = 'dock',
            height = s.geometry.height,
            width = s.geometry.width,
            x = s.geometry.x,
            y = s.geometry.y,
            bg = beautiful.background,
            fg = beautiful.fg_normal
        }
    )

    s.recorder_screen:setup {
        layout = wibox.layout.stack,
        {
            id = 'recorder_panel',
            visible = true,
            layout = wibox.layout.align.vertical,
            expand = 'none',
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = 'none',
                nil,
                {
                    layout = wibox.layout.fixed.vertical,
                    record_tbl.screen_rec_countdown_txt,
                    {
                        layout = wibox.layout.align.horizontal,
                        record_tbl.screen_rec_settings_button,
                        record_tbl.screen_rec_main_button,
                        record_tbl.screen_rec_audio_button
                    },
                    record_tbl.screen_rec_close_button,
                },
                nil

            },
            nil
        },
        {
            id = 'recorder_settings',
            visible = false,
            layout = wibox.layout.align.vertical,
            expand = 'none',
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = 'none',
                nil,
                {
                    layout = wibox.layout.fixed.vertical,
                    forced_width = dpi(316),
                    spacing = dpi(10),
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(10),
                        record_tbl.screen_rec_back_button,
                        record_tbl.screen_rec_back_txt,
                    },
                    record_tbl.screen_rec_source_txt,
                    record_tbl.screen_rec_source_rows,
                    record_tbl.screen_rec_area_txt,
                    record_tbl.screen_rec_area_txtbox,
                    record_tbl.screen_rec_area_hint
                },
                nil

            },
            nil
        }
    }
end)

return record_tbl

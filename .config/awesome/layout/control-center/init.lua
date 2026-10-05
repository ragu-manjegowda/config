local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local center_backdrop = require('layout.center-backdrop')
local center_manager = require('layout.center-manager')
local center_geometry = require('layout.center-geometry')
local machine = require('library.machine')
local dpi = beautiful.xresources.apply_dpi

local format_item = function(widget)
    return wibox.widget {
        {
            {
                layout = wibox.layout.align.vertical,
                expand = 'none',
                nil,
                widget,
                nil
            },
            margins = dpi(10),
            widget = wibox.container.margin
        },
        forced_height = dpi(88),
        bg = beautiful.groups_bg,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
        end,
        widget = wibox.container.background
    }
end

local format_item_no_fix_height = function(widget)
    return wibox.widget {
        {
            {
                layout = wibox.layout.align.vertical,
                expand = 'none',
                nil,
                widget,
                nil
            },
            margins = dpi(10),
            widget = wibox.container.margin
        },
        bg = beautiful.groups_bg,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
        end,
        widget = wibox.container.background
    }
end

local vertical_separator = wibox.widget {
    orientation = 'vertical',
    forced_height = dpi(1),
    forced_width = dpi(1),
    span_ratio = 0.55,
    widget = wibox.widget.separator
}

local control_center_row_one = wibox.widget {
    layout = wibox.layout.align.horizontal,
    forced_height = dpi(48),
    nil,
    format_item(
        require('widget.user-profile')()
    ),
    {
        format_item(
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(10),
                require('widget.control-center-switch')(),
                vertical_separator,
                require('widget.end-session')()
            }
        ),
        left = dpi(10),
        widget = wibox.container.margin
    }
}

local main_control_row_two = wibox.widget {
    layout = wibox.layout.flex.horizontal,
    spacing = dpi(10),
    format_item_no_fix_height(
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            require('widget.airplane-mode'),
            require('widget.bluetooth-toggle'),
            require('widget.blue-light'),
            (require('widget.microphone-toggle'))
        }
    ),
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
        format_item(require('widget.dont-disturb')),
        format_item(require('widget.blur-toggle')),
        format_item(require('widget.presentation-mode'))
    }
}

local slider_items = {
    id = 'control_sliders',
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(10),
}
local function add_slider(name, flexible_height)
    local contents = {
        require('widget.' .. name),
        margins = dpi(10),
        widget = wibox.container.margin
    }
    slider_items[#slider_items + 1] = flexible_height and format_item_no_fix_height(contents) or format_item(contents)
end
if machine.power_profile then add_slider('power-profile', true) end
add_slider('blur-slider')
add_slider('brightness-slider')
add_slider('volume-slider')
if machine.keyboard_backlight then add_slider('kbd-brightness-slider') end
local main_control_row_sliders = wibox.widget(slider_items)

local monitor_control_row_progressbars = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(10),
    format_item(
        require('widget.cpu-meter')
    ),
    format_item(
        require('widget.ram-meter')
    ),
    format_item(
        require('widget.temperature-meter')
    ),
    format_item(
        require('widget.harddrive-meter')
    )
}

local control_center = function(s)
    -- Set the control center geometry
    local panel_width = center_geometry.width(s)

    local panel = awful.popup {
        widget = {
            {
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(10),
                    control_center_row_one,
                    {
                        layout = wibox.layout.stack,
                        {
                            id = 'main_control',
                            visible = true,
                            layout = wibox.layout.fixed.vertical,
                            spacing = dpi(10),
                            main_control_row_two,
                            main_control_row_sliders,
                        },
                        {
                            id = 'monitor_control',
                            visible = false,
                            layout = wibox.layout.fixed.vertical,
                            spacing = dpi(10),
                            monitor_control_row_progressbars
                        }
                    }
                },
                margins = dpi(16),
                widget = wibox.container.margin
            },
            id = 'control_center',
            bg = beautiful.background,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
            end,
            widget = wibox.container.background
        },
        screen = s,
        type = 'dock',
        visible = false,
        ontop = true,
        width = panel_width,
        maximum_width = panel_width,
        bg = beautiful.transparent,
        fg = beautiful.fg_normal,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
        end,
    }

    center_geometry.bind(panel, s, 'top_right')

    panel.opened = false

    s.backdrop_control_center = wibox {
        ontop = true,
        screen = s,
        bg = beautiful.transparent,
        type = 'utility',
        x = s.geometry.x,
        y = s.geometry.y,
        width = s.geometry.width,
        height = s.geometry.height
    }

    local open_panel = function()
        center_manager.open(panel)
        panel.opened = true
        center_backdrop.show(s.backdrop_control_center, s)
        panel.visible = true

        local monitor = panel.widget:get_children_by_id('monitor_control')[1]
        awesome.emit_signal('control_center::visibility', true)
        awesome.emit_signal('control_center::monitor_visibility', monitor.visible)

        panel:emit_signal('opened')
    end

    local close_panel = function()
        panel.opened = false
        panel.visible = false
        s.backdrop_control_center.visible = false
        center_manager.close(panel)

        awesome.emit_signal('control_center::visibility', false)
        awesome.emit_signal('control_center::monitor_visibility', false)

        panel:emit_signal('closed')
    end

    -- Hide this panel when app dashboard is called.
    function panel:hide_dashboard()
        close_panel()
    end

    function panel:toggle()
        if self.opened then
            close_panel()
        else
            open_panel()
        end
    end

    s.backdrop_control_center:buttons(
        awful.util.table.join(
            awful.button(
                {},
                1,
                nil,
                function()
                    panel:toggle()
                end
            )
        )
    )

    return panel
end

return control_center

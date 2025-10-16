local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local dpi = require('beautiful').xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/tray-toggle/icons/'

-- Keep track of all widget instances
local widget_instances = {}

-- Setup global signal handler (only once)
if not awesome._tray_toggle_signal_setup then
    awesome._tray_toggle_signal_setup = true

    awesome.connect_signal(
        'widget::systray:toggle',
        function()
            -- Find which screen has the systray
            local systray_screen = nil
            for s in screen do
                if s.systray then
                    systray_screen = s
                    break
                end
            end

            if systray_screen and systray_screen.systray then
                systray_screen.systray.visible = not systray_screen.systray.visible

                -- Update all widget instances
                local icon_name = systray_screen.systray.visible and 'right-arrow.svg' or 'left-arrow.svg'
                for _, w in ipairs(widget_instances) do
                    if w.icon then
                        ---@diagnostic disable-next-line: param-type-mismatch
                        w.icon:set_image(gears.surface.load_uncached(widget_icon_dir .. icon_name))
                    end
                end
            end
        end
    )
end

-- Create a factory function to return a widget instance per screen
return function()
    local widget = wibox.widget {
        {
            id = 'icon',
            image = widget_icon_dir .. 'right-arrow' .. '.svg',
            widget = wibox.widget.imagebox,
            resize = true
        },
        layout = wibox.layout.align.horizontal
    }

    local widget_button = wibox.widget {
        {
            widget,
            margins = dpi(7),
            widget = wibox.container.margin
        },
        widget = clickable_container
    }

    widget_button:buttons(
        gears.table.join(
            awful.button(
                {},
                1,
                nil,
                function()
                    awesome.emit_signal('widget::systray:toggle')
                end
            )
        )
    )

    -- Store this widget instance
    table.insert(widget_instances, widget)

    -- Update icon on start-up
    local systray_screen = nil
    for s in screen do
        if s.systray then
            systray_screen = s
            break
        end
    end

    if systray_screen and systray_screen.systray then
        local icon_name = systray_screen.systray.visible and 'right-arrow.svg' or 'left-arrow.svg'
        ---@diagnostic disable-next-line: param-type-mismatch
        widget.icon:set_image(gears.surface.load_uncached(widget_icon_dir .. icon_name))
    end

    return widget_button
end

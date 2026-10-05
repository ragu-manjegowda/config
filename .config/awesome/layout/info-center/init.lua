local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local suspension = require('library.notification-suspension')
local center_backdrop = require('layout.center-backdrop')
local center_manager = require('layout.center-manager')
local center_geometry = require('layout.center-geometry')

local open_centers = setmetatable({}, { __mode = 'k' })

local function update_suspension()
    suspension.set('center_open', next(open_centers) ~= nil)
end

local info_center = function(s)
    -- Set the info center geometry
    local panel_width = center_geometry.width(s)
    local sections = {
        require('widget.notif-center')(s),
        require('widget.email'),
        require('widget.stocks'),
        require('widget.calendar-events'),
        (require('widget.weather')),
    }

    local panel = awful.popup {
        widget = {
            {
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(10),
                    sections[1], sections[2], sections[3], sections[4], sections[5]
                    -- require('widget.email')
                },
                margins = dpi(16),
                widget = wibox.container.margin
            },
            id = 'info_center',
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
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
    }

    center_geometry.bind(panel, s, 'top_right')

    local sizing = false
    local function size_sections()
        if sizing then return end
        sizing = true
        center_geometry.fit_sections(panel, s, sections)
        sizing = false
    end
    panel:connect_signal('property::maximum_height', size_sections)
    panel:connect_signal('property::width', size_sections)
    local queued = false
    for _, section in ipairs(sections) do
        section:connect_signal('widget::layout_changed', function()
            if sizing or queued or not panel.visible then return end
            queued = true
            gears.timer.delayed_call(function()
                queued = false
                if panel.visible then size_sections() end
            end)
        end)
    end

    panel.opened = false

    s.backdrop_info_center = wibox {
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
        open_centers[panel] = true
        update_suspension()
        center_backdrop.show(s.backdrop_info_center, s)
        size_sections()
        panel.visible = true

        awesome.emit_signal('info_center::visibility', true)

        panel:emit_signal('opened')
        --Not a good idea because we have API rate limit
        --awesome.emit_signal('widget::update_stocks')
    end

    local close_panel = function()
        panel.opened = false
        open_centers[panel] = nil
        update_suspension()
        panel.visible = false
        s.backdrop_info_center.visible = false
        center_manager.close(panel)

        awesome.emit_signal('info_center::visibility', false)

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

    local removed_handler
    removed_handler = function(removed)
        if removed ~= s then
            return
        end
        open_centers[panel] = nil
        center_manager.close(panel)
        update_suspension()
        screen.disconnect_signal('removed', removed_handler)
    end
    screen.connect_signal('removed', removed_handler)

    s.backdrop_info_center:buttons(
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

return info_center

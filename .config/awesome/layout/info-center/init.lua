local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local suspension = require('library.notification-suspension')

PANEL_VISIBLE = false
local open_centers = setmetatable({}, { __mode = 'k' })
local active_panel

local function update_suspension()
    PANEL_VISIBLE = next(open_centers) ~= nil
    suspension.set('center_open', PANEL_VISIBLE)
end

local info_center = function(s)
    -- Set the info center geometry
    local panel_width = s.geometry.width / 6

    local panel = awful.popup {
        widget = {
            {
                {
                    layout = wibox.layout.fixed.vertical,
                    forced_width = dpi(panel_width),
                    spacing = dpi(10),
                    require('widget.notif-center')(s),
                    require('widget.email'),
                    require('widget.stocks'),
                    require('widget.calendar-events'),
                    (require('widget.weather'))
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
        width = dpi(panel_width),
        maximum_width = dpi(panel_width),
        maximum_height = dpi(s.geometry.height - 38),
        bg = beautiful.transparent,
        fg = beautiful.fg_normal,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
        end,
    }

    awful.placement.top_right(
        panel,
        {
            honor_workarea = true,
            parent = s,
            margins = {
                top = (s.geometry.height / 22) + 10,
                right = dpi(10)
            }
        }
    )

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
        if active_panel and active_panel ~= panel then
            active_panel:hide_dashboard()
        end
        active_panel = panel
        panel.opened = true
        open_centers[panel] = true
        update_suspension()
        s.backdrop_info_center.visible = true
        panel.visible = true

        awesome.emit_signal('info_center::visibility', true)

        panel:emit_signal('opened')
        --Not a good idea because we have API rate limit
        --awesome.emit_signal('widget::update_stocks')
    end

    local close_panel = function()
        if active_panel == panel then
            active_panel = nil
        end
        panel.opened = false
        open_centers[panel] = nil
        if active_panel == panel then
            active_panel = nil
        end
        update_suspension()
        panel.visible = false
        s.backdrop_info_center.visible = false

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

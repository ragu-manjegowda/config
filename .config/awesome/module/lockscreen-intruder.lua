local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local wibox = require('wibox')
local dpi = beautiful.xresources.apply_dpi
local default_image = gears.filesystem.get_configuration_dir() ..
    'configuration/user-profile/default.svg'

local intruder = {}
local posters = {}
local current_capture

local function place(poster, s)
    if not s.valid then return end
    awful.placement.top(poster, {
        parent = s,
        honor_workarea = false,
        margins = { top = dpi(10) }
    })
end

local function show(entry, capture)
    entry.image:set_image(capture.image)
    entry.message:set_text(capture.message)
    entry.popup.visible = true
    place(entry.popup, entry.screen)
end

function intruder.attach(s)
    if not s.valid then return nil end
    if posters[s] then return posters[s].popup end

    -- Each screen needs independent widgets as well as its own popup.
    local title = wibox.widget {
        text = 'INTRUDER ALERT!',
        font = beautiful.font_bold(14),
        align = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    }
    local image = wibox.widget {
        image = default_image,
        resize = true,
        forced_height = dpi(120),
        clip_shape = gears.shape.rounded_rect,
        widget = wibox.widget.imagebox
    }
    local message = wibox.widget {
        font = beautiful.font_regular(12),
        align = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    }
    local popup = awful.popup {
        screen = s,
        widget = {
            {
                {
                    title,
                    {
                        nil,
                        image,
                        nil,
                        expand = 'none',
                        layout = wibox.layout.align.horizontal
                    },
                    message,
                    spacing = dpi(5),
                    layout = wibox.layout.fixed.vertical
                },
                margins = dpi(20),
                widget = wibox.container.margin
            },
            bg = beautiful.background,
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background
        },
        bg = beautiful.transparent,
        type = 'utility',
        ontop = true,
        shape = gears.shape.rectangle,
        maximum_width = dpi(250),
        maximum_height = dpi(250),
        hide_on_right_click = false,
        visible = false,
        -- awful.popup reapplies this after its asynchronous content sizing.
        placement = function(poster) place(poster, s) end
    }
    local entry = { screen = s, popup = popup, image = image, message = message }
    posters[s] = entry
    s.intruder_alert = popup
    if current_capture then show(entry, current_capture) end
    return popup
end

function intruder.show(image, message)
    current_capture = { image = image, message = message }
    for s, entry in pairs(posters) do
        if s.valid then show(entry, current_capture) end
    end
end

function intruder.hide()
    current_capture = nil
    for _, entry in pairs(posters) do entry.popup.visible = false end
end

screen.connect_signal('property::geometry', function(s)
    local entry = posters[s]
    if entry then place(entry.popup, s) end
end)

screen.connect_signal('removed', function(s)
    local entry = posters[s]
    if not entry then return end
    entry.popup.visible = false
    posters[s] = nil
end)

return intruder

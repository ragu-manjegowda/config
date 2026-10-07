-- Exercise the real popup manager with a closed-lid primary and offset outputs.
local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local handlers, popups = {}, {}
screen = { connect_signal = function(name, callback) handlers[name] = callback end }
local function output(x, y, width, height)
    return { valid = true, geometry = { x = x, y = y, width = width, height = height } }
end
local internal = output(0, 0, 2880, 1800)
local external = output(2880, 0, 3440, 1440)
screen.primary = internal

local function widget(args)
    args.mock_widget = true
    function args:set_image(image) self.image = image end

    function args:set_text(text) self.text = text end

    return args
end
package.loaded.wibox = {
    widget = setmetatable({ textbox = {}, imagebox = {} }, {
        __call = function(_, args) return widget(args) end
    }),
    container = { margin = {}, background = {} },
    layout = { align = { horizontal = {} }, fixed = { vertical = {} } }
}
package.loaded.beautiful = {
    background = 'background',
    transparent = 'transparent',
    font_bold = function() return 'bold' end,
    font_regular = function() return 'regular' end,
    xresources = { apply_dpi = function(value) return value end }
}
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return root end },
    shape = { rounded_rect = {}, rectangle = {} }
}
package.loaded.awful = {
    popup = function(args)
        args.screen = args.screen or screen.primary
        args.width, args.height = 240, 230
        popups[#popups + 1] = args
        return args
    end,
    placement = {
        top = function(popup, args)
            local parent = args.parent or popup.screen
            popup.x = parent.geometry.x + (parent.geometry.width - popup.width) / 2
            popup.y = parent.geometry.y + args.margins.top
            popup.parent = parent
        end
    }
}
local intruder = require('module.lockscreen-intruder')
local primary_poster, external_poster = intruder.attach(internal), intruder.attach(external)
assert(#popups == 2 and primary_poster ~= external_poster)
assert(primary_poster.screen == internal and external_poster.screen == external,
    'Every popup must belong to its own output, regardless of primary or pointer')
assert(not primary_poster.visible and not external_poster.visible)
assert(intruder.attach(external) == external_poster and #popups == 2,
    'Repeated decoration must reuse the existing popup')

local function content(poster)
    local body = poster.widget[1][1]
    return body[2][2], body[3]
end
local primary_image, primary_message = content(primary_poster)
local external_image, external_message = content(external_poster)
assert(primary_image ~= external_image and primary_message ~= external_message,
    'Widgets must not be shared across popup hierarchies')
intruder.show('/private/suspect.png', 'Authentication failed!')
for _, poster in ipairs({ primary_poster, external_poster }) do
    local image, message = content(poster)
    assert(poster.visible and poster.ontop)
    assert(image.image == '/private/suspect.png' and message.text == 'Authentication failed!')
    assert(poster.parent == poster.screen and poster.y == 10)
end
assert(external_poster.x >= external.geometry.x,
    'The alert must be visible on the external output even with the laptop closed')

-- Popup sizing is asynchronous in Awesome; its placement must remain output-bound.
external_poster.width = 180
external_poster.placement(external_poster)
assert(external_poster.x == 2880 + (3440 - 180) / 2)
external.geometry = { x = -1920, y = 180, width = 1920, height = 1080 }
handlers['property::geometry'](external)
assert(external_poster.x == -1920 + (1920 - 180) / 2 and external_poster.y == 190,
    'An active alert must follow RandR moves/resizes, including negative coordinates')

local added = output(0, -1080, 1920, 1080)
local added_poster = intruder.attach(added)
assert(added_poster.visible and added_poster.y == -1070,
    'A newly connected display must mirror the active capture')
assert(content(added_poster).image == '/private/suspect.png')
external.valid = false
handlers.removed(external)
assert(not external_poster.visible, 'Unplugging an output must retire its alert')
local removed_x = external_poster.x
handlers['property::geometry'](external)
assert(external_poster.x == removed_x)

intruder.hide()
for _, poster in ipairs(popups) do assert(not poster.visible, 'Unlock must hide every alert') end
local later = output(2880, 0, 3440, 1440)
local later_poster = intruder.attach(later)
assert(not later_poster.visible, 'New outputs after unlock must not replay an old capture')
assert(intruder.attach({ valid = false }) == nil)
intruder.show('/private/next-suspect.png', 'Next attempt')
assert(not external_poster.visible, 'A removed popup must never be shown again')
for _, poster in ipairs({ primary_poster, added_poster, later_poster }) do
    assert(poster.visible and content(poster).image == '/private/next-suspect.png')
end
intruder.hide()

print('per-screen intruder alerts, asynchronous placement, hotplug and unlock cleanup tests passed')

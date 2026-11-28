local filesystem = require('gears.filesystem')
local symbolic = require('theme.symbolic')
local icons = {}
local root = filesystem.get_configuration_dir():gsub('/+$', '') .. '/'
local directories = {
    ['theme/icons/touchpad/'] = true,
    ['widget/airplane-mode/icons/'] = true,
    ['widget/battery/icons/'] = true,
    ['widget/bluetooth-toggle/icons/'] = true,
    ['widget/email/icons/'] = true,
    ['widget/notif-center/icons/'] = true,
}

function icons.source(value)
    if type(value) ~= 'string' then return nil end
    local path = value:gsub('^file://', ''):gsub('/+', '/')
    if path:sub(1, #root) ~= root then return nil end
    local relative = path:sub(#root + 1)
    if relative == 'theme/icons/awesome.svg' or directories[relative:match('^(.+/)[%w_%-]+%.svg$')] then
        return path
    end
end

function icons.popup(notification)
    local wibox = require('wibox')
    local native = require('naughty').widget.icon { notification = notification }
    native.resize_strategy = 'center'
    local container = wibox.container.place()
    local glyph
    local function update()
        local path = icons.source(notification.icon) or icons.source(notification.app_icon)
        if path then
            glyph = glyph or symbolic.imagebox()
            local size = notification.icon_size or require('beautiful').notification_icon_size
            glyph.forced_width, glyph.forced_height = size, size
            glyph.halign, glyph.valign = 'center', 'center'
            glyph.downscale, glyph.upscale = true, false
            glyph.image = path
        end
        container.widget = path and glyph or native
    end
    container._private.update_notification_icon = update
    notification:weak_connect_signal('property::icon', update)
    update()
    return container
end

return icons

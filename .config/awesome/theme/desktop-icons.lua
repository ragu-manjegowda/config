local beautiful = require('beautiful')
local filesystem = require('gears.filesystem')
local resolver, active_theme

return function(name, size)
    if type(name) ~= 'string' or name == '' then return nil end
    if name:sub(1, 1) == '/' then return filesystem.file_readable(name) and name or nil end
    if name:find('/', 1, true) then return nil end
    if not resolver then
        resolver = require('lgi').require('Gtk', '3.0').IconTheme.new()
    end
    if beautiful.icon_theme ~= active_theme then
        active_theme = beautiful.icon_theme
        resolver:set_custom_theme(active_theme)
    end
    name = name:gsub('%.svg$', ''):gsub('%.png$', ''):gsub('%.xpm$', '')
    size = size or beautiful.notification_icon_size
    local info = resolver:lookup_icon(name, size, 0)
    if not info and name ~= name:lower() then info = resolver:lookup_icon(name:lower(), size, 0) end
    return info and info:get_filename()
end

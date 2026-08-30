local gears = require('gears')
local beautiful = require('beautiful')

local icons = {}
local directory = gears.filesystem.get_configuration_dir() ..
    'widget/screen-recorder/icons/'

local function recolor(name, color)
    return gears.color.recolor_image(directory .. name .. '.svg', color)
end

function icons.normal(name)
    return recolor(name, beautiful.fg_normal)
end

function icons.accent(name)
    return recolor(name, beautiful.accent)
end

function icons.urgent(name)
    return recolor(name, beautiful.bg_urgent)
end

return icons

local gears = require('gears')

local icons = {}
local directory = gears.filesystem.get_configuration_dir() ..
    'widget/screen-recorder/icons/'

local function icon(name, role)
    return { path = directory .. name .. '.svg', role = role }
end

function icons.normal(name)
    return icon(name, 'fg_normal')
end

function icons.accent(name)
    return icon(name, 'accent')
end

function icons.urgent(name)
    return icon(name, 'bg_urgent')
end

return icons

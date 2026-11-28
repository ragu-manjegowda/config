local awful = require('awful')
local bindings = require('theme.bindings')
local tooltip = {}

function tooltip.attach(tip)
    bindings.bind(tip.backgroundbox, { bg = 'tooltip_bg', fg = 'tooltip_fg', border_color = 'tooltip_border_color' })
    return tip
end

function tooltip.new(args)
    return tooltip.attach(awful.tooltip(args))
end

return tooltip

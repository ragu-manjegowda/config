local gtable = require('gears.table')
local default_theme = require('theme.default-theme')

-- PICK THEME HERE
local theme = require('theme.solarized-light-theme')

local final_theme = {}
gtable.crush(final_theme, default_theme.theme, true)
gtable.crush(final_theme, theme.theme, true)
default_theme.awesome_overrides(final_theme)
theme.awesome_overrides(final_theme)

return final_theme

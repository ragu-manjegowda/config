local filesystem = require('gears.filesystem')
local theme_dir = filesystem.get_configuration_dir() .. '/theme'

local theme = {}

theme.icons = theme_dir .. '/icons/'
theme.font = 'Hack Nerd Regular 12'
theme.font_bold = 'Hack Nerd Bold 12'

theme.colors = {}
theme.colors.base3   = "#002b36"
theme.colors.base2   = "#073642"
theme.colors.base1   = "#586e75"
theme.colors.base0   = "#657b83"
theme.colors.base00  = "#839496"
theme.colors.base01  = "#93a1a1"
theme.colors.base02  = "#eee8d5"
theme.colors.base03  = "#fdf6e366"
theme.colors.yellow  = "#b58900"
theme.colors.orange  = "#cb4b16"
theme.colors.red     = "#dc322f"
theme.colors.magenta = "#d33682"
theme.colors.violet  = "#6c71c4"
theme.colors.blue    = "#268bd2"
theme.colors.cyan    = "#2aa198"
theme.colors.green   = "#859900"

-- Colorscheme
theme.system_black_dark = theme.colors.base3
theme.system_black_light = theme.colors.base2

theme.system_red_dark = theme.colors.orange
theme.system_red_light = theme.colors.red

theme.system_green_dark = theme.colors.base1
theme.system_green_light = theme.colors.green

theme.system_yellow_dark = theme.colors.base0
theme.system_yellow_light = theme.colors.yellow

theme.system_blue_dark = theme.colors.base00
theme.system_blue_light = theme.colors.blue

theme.system_magenta_dark = theme.colors.violet
theme.system_magenta_light = theme.colors.magenta

theme.system_cyan_dark = theme.colors.base01
theme.system_cyan_light = theme.colors.cyan

theme.system_white_dark = theme.colors.base03
theme.system_white_light = theme.colors.base02

-- Accent color
theme.accent = theme.system_blue_light

-- Background color
theme.background = theme.system_white_dark
theme.background_light = theme.system_white_light

-- Transparent
theme.transparent = '#00000000'

-- Foreground
theme.fg_normal = theme.system_black_light
theme.fg_focus = theme.colors.base3
theme.fg_urgent = theme.colors.base03

theme.bg_normal = theme.background
theme.bg_focus = theme.colors.base01
theme.bg_urgent = theme.system_red_dark

-- Borders
theme.border_focus = theme.bg_focus
theme.border_normal = theme.bg_normal
theme.border_marked = theme.bg_urgent

-- Titlebar
theme.titlebar_bg_normal = theme.bg_normal
theme.titlebar_bg_focus = theme.bg_focus
theme.titlebar_fg_focus = theme.fg_focus
theme.titlebar_fg_normal = theme.fg_normal

-- Mouse finder
theme.mouse_finder_color = theme.system_green_dark

-- Taglist
theme.taglist_bg_empty = theme.accent .. '33'
theme.taglist_bg_occupied = theme.background
theme.taglist_bg_urgent = theme.bg_urgent
theme.taglist_bg_focus = theme.bg_focus

-- Tasklist
theme.tasklist_bg_normal = theme.background_light
theme.tasklist_bg_focus = theme.bg_focus
theme.tasklist_bg_urgent = theme.bg_urgent
theme.tasklist_fg_focus = theme.fg_focus
theme.tasklist_fg_urgent = theme.fg_urgent
theme.tasklist_fg_normal = theme.fg_normal

-- UI Groups
theme.groups_title_bg = theme.background
theme.groups_bg = theme.background_light

-- UI events
theme.leave_event = transparent
theme.enter_event = '#ffffff' .. '10'
theme.press_event = '#ffffff' .. '15'
theme.release_event = '#ffffff' .. '10'

-- Awesome icon
theme.awesome_icon = theme.icons .. 'awesome.svg'

local awesome_overrides = function(theme) end

return {
	theme = theme,
 	awesome_overrides = awesome_overrides
}

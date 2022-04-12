local gears = require('gears')
local beautiful = require('beautiful')

local filesystem = gears.filesystem
local dpi = beautiful.xresources.apply_dpi
local gtk_variable = beautiful.gtk.get_theme_variables

local theme_dir = filesystem.get_configuration_dir() .. '/theme'
local titlebar_theme = 'stoplight'
local titlebar_icon_path = theme_dir .. '/icons/titlebar/' .. titlebar_theme .. '/'
local tip = titlebar_icon_path

-- Create theme table
local theme = {}

-- Font
theme.font = 'Hack Nerd Regular 10'
theme.font_bold = 'Hack Nerd Bold 10'
theme.notification_font = 'Hack Nerd Regular 10, Noto Color Emoji'
theme.emojifont = 'Hack Nerd Regular 10, Noto Color Emoji'

-- Menu icon theme
theme.icon_theme = 'Tela-blue-dark'

local awesome_overrides = function(theme)

	theme.dir = theme_dir
	theme.icons = theme_dir .. '/icons/'

	-- Default wallpaper path
	theme.wallpaper = theme.dir .. '/wallpapers/morning-wallpaper.jpg'

	-- Default font
	theme.font = 'Hack Nerd Regular 10'
	theme.notification_font = 'Hack Nerd Regular 10, Noto Color Emoji'
	theme.emojifont = 'Hack Nerd Regular 10, Noto Color Emoji'

	-- System tray
	theme.bg_systray = theme.background
	theme.systray_icon_spacing = dpi(16)

	-- Titlebar
	theme.titlebar_size = dpi(34)

	-- Close Button
	theme.titlebar_close_button_normal = tip .. 'close_normal.svg'
	theme.titlebar_close_button_focus  = tip .. 'close_focus.svg'

	-- Minimize Button
	theme.titlebar_minimize_button_normal = tip .. 'minimize_normal.svg'
	theme.titlebar_minimize_button_focus  = tip .. 'minimize_focus.svg'

	-- Ontop Button
	theme.titlebar_ontop_button_normal_inactive = tip .. 'ontop_normal_inactive.svg'
	theme.titlebar_ontop_button_focus_inactive  = tip .. 'ontop_focus_inactive.svg'
	theme.titlebar_ontop_button_normal_active = tip .. 'ontop_normal_active.svg'
	theme.titlebar_ontop_button_focus_active  = tip .. 'ontop_focus_active.svg'

	-- Sticky Button
	theme.titlebar_sticky_button_normal_inactive = tip .. 'sticky_normal_inactive.svg'
	theme.titlebar_sticky_button_focus_inactive  = tip .. 'sticky_focus_inactive.svg'
	theme.titlebar_sticky_button_normal_active = tip .. 'sticky_normal_active.svg'
	theme.titlebar_sticky_button_focus_active  = tip .. 'sticky_focus_active.svg'

	-- Floating Button
	theme.titlebar_floating_button_normal_inactive = tip .. 'floating_normal_inactive.svg'
	theme.titlebar_floating_button_focus_inactive  = tip .. 'floating_focus_inactive.svg'
	theme.titlebar_floating_button_normal_active = tip .. 'floating_normal_active.svg'
	theme.titlebar_floating_button_focus_active  = tip .. 'floating_focus_active.svg'

	-- Maximized Button
	theme.titlebar_maximized_button_normal_inactive = tip .. 'maximized_normal_inactive.svg'
	theme.titlebar_maximized_button_focus_inactive  = tip .. 'maximized_focus_inactive.svg'
	theme.titlebar_maximized_button_normal_active = tip .. 'maximized_normal_active.svg'
	theme.titlebar_maximized_button_focus_active  = tip .. 'maximized_focus_active.svg'

	-- Hovered Close Button
	theme.titlebar_close_button_normal_hover = tip .. 'close_normal_hover.svg'
	theme.titlebar_close_button_focus_hover  = tip .. 'close_focus_hover.svg'

	-- Hovered Minimize Buttin
	theme.titlebar_minimize_button_normal_hover = tip .. 'minimize_normal_hover.svg'
	theme.titlebar_minimize_button_focus_hover  = tip .. 'minimize_focus_hover.svg'

	-- Hovered Ontop Button
	theme.titlebar_ontop_button_normal_inactive_hover = tip .. 'ontop_normal_inactive_hover.svg'
	theme.titlebar_ontop_button_focus_inactive_hover  = tip .. 'ontop_focus_inactive_hover.svg'
	theme.titlebar_ontop_button_normal_active_hover = tip .. 'ontop_normal_active_hover.svg'
	theme.titlebar_ontop_button_focus_active_hover  = tip .. 'ontop_focus_active_hover.svg'

	-- Hovered Sticky Button
	theme.titlebar_sticky_button_normal_inactive_hover = tip .. 'sticky_normal_inactive_hover.svg'
	theme.titlebar_sticky_button_focus_inactive_hover  = tip .. 'sticky_focus_inactive_hover.svg'
	theme.titlebar_sticky_button_normal_active_hover = tip .. 'sticky_normal_active_hover.svg'
	theme.titlebar_sticky_button_focus_active_hover  = tip .. 'sticky_focus_active_hover.svg'

	-- Hovered Floating Button
	theme.titlebar_floating_button_normal_inactive_hover = tip .. 'floating_normal_inactive_hover.svg'
	theme.titlebar_floating_button_focus_inactive_hover  = tip .. 'floating_focus_inactive_hover.svg'
	theme.titlebar_floating_button_normal_active_hover = tip .. 'floating_normal_active_hover.svg'
	theme.titlebar_floating_button_focus_active_hover  = tip .. 'floating_focus_active_hover.svg'

	-- Hovered Maximized Button
	theme.titlebar_maximized_button_normal_inactive_hover = tip .. 'maximized_normal_inactive_hover.svg'
	theme.titlebar_maximized_button_focus_inactive_hover  = tip .. 'maximized_focus_inactive_hover.svg'
	theme.titlebar_maximized_button_normal_active_hover = tip .. 'maximized_normal_active_hover.svg'
	theme.titlebar_maximized_button_focus_active_hover  = tip .. 'maximized_focus_active_hover.svg'

	-- UI Groups
	theme.groups_radius = dpi(16)

	-- Client Decorations

	-- Borders
	theme.border_width = dpi(0)
	theme.border_radius = dpi(12)

	-- Decorations
	theme.useless_gap = dpi(4)
	theme.client_shape_rounded = function(cr, width, height)
		gears.shape.rounded_rect(cr, width, height, dpi(12))
	end

	-- Menu
	theme.menu_font = 'Hack Nerd Regular 11'
	theme.menu_submenu = '' -- ➤

	theme.menu_height = dpi(34)
	theme.menu_width = dpi(200)
	theme.menu_border_width = dpi(20)
	theme.menu_bg_focus = theme.accent

	theme.menu_bg_normal =  theme.background
	theme.menu_fg_normal = theme.fg_normal
	theme.menu_fg_focus = theme.fg_focus
	theme.menu_border_color = theme.background:sub(1,7) .. '5C'

	-- Tooltips

	theme.tooltip_bg = theme.accent
	theme.tooltip_fg = theme.system_white_light
	theme.tooltip_border_color = theme.background
	theme.tooltip_border_width = 0
	theme.tooltip_gaps = dpi(5)
	theme.tooltip_shape = function(cr, w, h)
		gears.shape.rounded_rect(cr, w, h, dpi(6))
	end

	-- Separators
	theme.separator_color = theme.accent

	-- Layoutbox icons
	theme.layout_max = theme.icons .. 'layouts/max.png'
	theme.layout_tile = theme.icons .. 'layouts/tile.png'
	theme.layout_dwindle = theme.icons .. 'layouts/dwindle.png'
	theme.layout_floating = theme.icons .. 'layouts/floating.png'

	-- Taglist
	theme.taglist_spacing = dpi(0)

	-- Tasklist
	theme.tasklist_font = 'Hack Nerd Regular 10'

	-- Notification
	theme.notification_position = 'top_left'
	theme.notification_bg = theme.background
	theme.notification_margin = dpi(5)
	theme.notification_border_width = dpi(0)
	theme.notification_border_color = theme.background_light
	theme.notification_spacing = dpi(5)
	theme.notification_icon_resize_strategy = 'center'
	theme.notification_icon_size = dpi(32)

	-- Client Snap Theme
	theme.snap_bg = theme.background
	theme.snap_shape = gears.shape.rectangle
	theme.snap_border_width = dpi(15)

	-- Hotkey popup
	theme.hotkeys_font = 'Hack Nerd Bold 14'
	theme.hotkeys_description_font   = 'Hack Nerd Regular Regular 12'
	theme.hotkeys_bg = theme.background
	theme.hotkeys_group_margin = dpi(20)
end

return {
	theme = theme,
	awesome_overrides = awesome_overrides
}

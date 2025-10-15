local gears = require('gears')
local beautiful = require('beautiful')

local filesystem = gears.filesystem
local dpi = beautiful.xresources.apply_dpi

local theme_dir = filesystem.get_configuration_dir() .. '/theme'
local titlebar_theme = 'stoplight'
local titlebar_icon_path = theme_dir .. '/icons/titlebar/' .. titlebar_theme .. '/'
local tip = titlebar_icon_path

-- Create theme table
local theme = {}

-- Font size function - NO scaling (fonts stay at specified size)
-- The xrandr DPI setting affects layout/spacing via dpi() function, not fonts
-- This keeps fonts readable at any resolution
local function font_size(size)
    return size
end

-- Helper functions to create font strings with DPI scaling
local function font_regular(size)
    return 'Hack Nerd Regular ' .. font_size(size)
end

local function font_bold(size)
    return 'Hack Nerd Bold ' .. font_size(size)
end

local function font_italic(size)
    return 'Hack Nerd Italic ' .. font_size(size)
end

local function font_mono(size)
    return 'Hack Nerd Font Mono ' .. font_size(size)
end

local function font_emoji(size)
    return 'Hack Nerd Regular ' .. font_size(size) .. ', Noto Color Emoji'
end

-- Export font functions for use in widgets (MUST be before any widget loading)
theme.font_regular = font_regular
theme.font_bold = font_bold
theme.font_italic = font_italic
theme.font_mono = font_mono
theme.font_emoji = font_emoji
theme.font_size = font_size

-- Font - Now with DPI scaling
theme.font = font_regular(12)
theme.notification_font = font_emoji(12)
theme.emojifont = font_emoji(12)

---@diagnostic disable-next-line: redefined-local
local awesome_overrides = function(theme)

    theme.dir = theme_dir
    theme.icons = theme_dir .. '/icons/'

    -- Default wallpaper path
    theme.wallpaper = theme.dir .. '/wallpapers/morning-wallpaper.jpg'

    -- Re-export font functions after theme merge (in case they were overwritten)
    theme.font_regular = font_regular
    theme.font_bold = font_bold
    theme.font_italic = font_italic
    theme.font_mono = font_mono
    theme.font_emoji = font_emoji
    theme.font_size = font_size

    -- Default font (using DPI-scaled versions)
    theme.font = font_regular(12)
    theme.notification_font = font_emoji(12)
    theme.emojifont = font_emoji(12)

    -- System tray
    theme.bg_systray = theme.accent
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
    theme.titlebar_ontop_button_normal_active   = tip .. 'ontop_normal_active.svg'
    theme.titlebar_ontop_button_focus_active    = tip .. 'ontop_focus_active.svg'

    -- Sticky Button
    theme.titlebar_sticky_button_normal_inactive = tip .. 'sticky_normal_inactive.svg'
    theme.titlebar_sticky_button_focus_inactive  = tip .. 'sticky_focus_inactive.svg'
    theme.titlebar_sticky_button_normal_active   = tip .. 'sticky_normal_active.svg'
    theme.titlebar_sticky_button_focus_active    = tip .. 'sticky_focus_active.svg'

    -- Floating Button
    theme.titlebar_floating_button_normal_inactive = tip .. 'floating_normal_inactive.svg'
    theme.titlebar_floating_button_focus_inactive  = tip .. 'floating_focus_inactive.svg'
    theme.titlebar_floating_button_normal_active   = tip .. 'floating_normal_active.svg'
    theme.titlebar_floating_button_focus_active    = tip .. 'floating_focus_active.svg'

    -- Maximized Button
    theme.titlebar_maximized_button_normal_inactive = tip .. 'maximized_normal_inactive.svg'
    theme.titlebar_maximized_button_focus_inactive  = tip .. 'maximized_focus_inactive.svg'
    theme.titlebar_maximized_button_normal_active   = tip .. 'maximized_normal_active.svg'
    theme.titlebar_maximized_button_focus_active    = tip .. 'maximized_focus_active.svg'

    -- Hovered Close Button
    theme.titlebar_close_button_normal_hover = tip .. 'close_normal_hover.svg'
    theme.titlebar_close_button_focus_hover  = tip .. 'close_focus_hover.svg'

    -- Hovered Minimize Buttin
    theme.titlebar_minimize_button_normal_hover = tip .. 'minimize_normal_hover.svg'
    theme.titlebar_minimize_button_focus_hover  = tip .. 'minimize_focus_hover.svg'

    -- Hovered Ontop Button
    theme.titlebar_ontop_button_normal_inactive_hover = tip .. 'ontop_normal_inactive_hover.svg'
    theme.titlebar_ontop_button_focus_inactive_hover  = tip .. 'ontop_focus_inactive_hover.svg'
    theme.titlebar_ontop_button_normal_active_hover   = tip .. 'ontop_normal_active_hover.svg'
    theme.titlebar_ontop_button_focus_active_hover    = tip .. 'ontop_focus_active_hover.svg'

    -- Hovered Sticky Button
    theme.titlebar_sticky_button_normal_inactive_hover = tip .. 'sticky_normal_inactive_hover.svg'
    theme.titlebar_sticky_button_focus_inactive_hover  = tip .. 'sticky_focus_inactive_hover.svg'
    theme.titlebar_sticky_button_normal_active_hover   = tip .. 'sticky_normal_active_hover.svg'
    theme.titlebar_sticky_button_focus_active_hover    = tip .. 'sticky_focus_active_hover.svg'

    -- Hovered Floating Button
    theme.titlebar_floating_button_normal_inactive_hover = tip .. 'floating_normal_inactive_hover.svg'
    theme.titlebar_floating_button_focus_inactive_hover  = tip .. 'floating_focus_inactive_hover.svg'
    theme.titlebar_floating_button_normal_active_hover   = tip .. 'floating_normal_active_hover.svg'
    theme.titlebar_floating_button_focus_active_hover    = tip .. 'floating_focus_active_hover.svg'

    -- Hovered Maximized Button
    theme.titlebar_maximized_button_normal_inactive_hover = tip .. 'maximized_normal_inactive_hover.svg'
    theme.titlebar_maximized_button_focus_inactive_hover  = tip .. 'maximized_focus_inactive_hover.svg'
    theme.titlebar_maximized_button_normal_active_hover   = tip .. 'maximized_normal_active_hover.svg'
    theme.titlebar_maximized_button_focus_active_hover    = tip .. 'maximized_focus_active_hover.svg'

    -- UI Groups
    theme.groups_radius = dpi(16)

    -- Client Decorations

    -- Borders
    theme.border_width = dpi(0)
    theme.border_radius = dpi(12)

    -- Decorations
    theme.useless_gap = dpi(5)
    theme.client_shape_rounded = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, dpi(12))
    end

    -- Menu
    theme.menu_font = font_regular(13)
    theme.menu_submenu = '' -- ➤

    theme.menu_height = dpi(34)
    theme.menu_width = dpi(200)
    theme.menu_border_width = dpi(20)
    theme.menu_bg_focus = theme.accent

    theme.menu_bg_normal = theme.background
    theme.menu_fg_normal = theme.fg_normal
    theme.menu_fg_focus = theme.fg_focus
    theme.menu_border_color = theme.background:sub(1, 7) .. '5C'

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
    theme.taglist_spacing = dpi(2)

    -- Tasklist
    theme.tasklist_spacing = dpi(2)
    theme.tasklist_font = font_regular(12)

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
    theme.hotkeys_font             = font_bold(16)
    theme.hotkeys_description_font = font_regular(14)
    theme.hotkeys_bg               = theme.background
    theme.hotkeys_group_margin     = dpi(20)
end

return {
    theme = theme,
    awesome_overrides = awesome_overrides
}

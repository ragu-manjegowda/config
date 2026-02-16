-- ~/.config/yazi/init.lua

-- relative-motions.yazi plugin setup
-- show_numbers="relative" mirrors ranger's `set line_numbers relative`
-- show_motion=true shows current motion count in status bar
-- enter_mode="first" enters folders at the first item
require("relative-motions"):setup({
	show_numbers = "relative",
	show_motion = true,
	enter_mode = "first",
})

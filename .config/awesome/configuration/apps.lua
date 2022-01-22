local filesystem = require('gears.filesystem')
local config_dir = filesystem.get_configuration_dir()
local utils_dir = config_dir .. 'utilities/'

return {
	-- The default applications that we will use in keybindings and widgets
	default = {
		-- Default terminal emulator
		terminal = 'alacritty',
		-- Default web browser
		web_browser = 'google-chrome',
		-- Default text editor
		text_editor = 'nvim',
		-- Default file manager
		file_manager = 'ranger',
		-- Default media player
		multimedia = 'vlc',
		-- Default game, can be a launcher like steam
		game = '',
		-- Default graphics editor
		graphics = '',
		-- Default sandbox
		sandbox = '',
		-- Default IDE
		development = 'nvim',
		-- Default network manager
		network_manager = 'nm-applet',
		-- Default bluetooth manager
		bluetooth_manager = 'blueman-manager',
		-- Default power manager
		power_manager = 'xfce4-power-manager',
		-- Default GUI package manager
		package_manager = '',
		-- Default locker
		lock = 'awesome-client "awesome.emit_signal(\'module::lockscreen_show\')"',
		-- Default quake terminal
		quake = '',
		-- Default rofi global menu
		rofi_global = 'rofi -dpi ' .. screen.primary.dpi ..
							' -show "Global Search" -modi "Global Search":' .. config_dir ..
							'/configuration/rofi/global/rofi-spotlight.sh' ..
							' -theme ' .. config_dir ..
							'/configuration/rofi/global/rofi.rasi',
		-- Default app menu
		rofi_appmenu = 'rofi -dpi ' .. screen.primary.dpi ..
							' -show drun -theme ' .. config_dir ..
							'/configuration/rofi/appmenu/rofi.rasi'

		-- You can add more default applications here
	},

	-- List of apps to start once on start-up
	run_on_start_up = {
		-- Compositor
		'picom -b --experimental-backends --dbus --config ' ..
		config_dir .. '/configuration/picom.conf',
        -- Network applet
        'nm-applet',
		-- Blueman applet
		'blueman-applet',
		-- Music server
		'',
		-- Polkit and keyring
		--'/usr/bin/lxqt-policykit-agent &' ..
		--' eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg)',
		-- Load X colors
		'xrdb ~/.Xresources',
		-- Audio equalizer
		'',
		-- Lockscreen timer
		[[
		xidlehook --not-when-fullscreen --not-when-audio --timer 600 \
		"awesome-client 'awesome.emit_signal(\"module::lockscreen_show\")'" ""
		]],

		-- You can add more start-up applications here
        -- Use `xinput list` command to get touchpad device name
        -- `SynPS/2 Synaptics TouchPad` in this case
        'xinput set-prop "SynPS/2 Synaptics TouchPad" "libinput Tapping Enabled" 1'
	},

	-- List of binaries/shell scripts that will execute for a certain task
	utils = {
		-- Fullscreen screenshot
		full_screenshot = utils_dir .. 'snap full',
		-- Area screenshot
		area_screenshot = utils_dir .. 'snap area',
		-- Update profile picture
		update_profile  = utils_dir .. 'profile-image'
	}
}

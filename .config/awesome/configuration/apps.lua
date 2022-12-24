local filesystem = require('gears.filesystem')
local config_dir = filesystem.get_configuration_dir()
local utils_dir = config_dir .. 'utilities/'

return {
	-- The default applications that we will use in keybindings and widgets
	default = {
		-- Default terminal emulator
		terminal = 'alacritty',
		-- Default web browser
		web_browser = 'google-chrome-stable',
		-- Default text editor
		text_editor = 'nvim',
		-- Default file manager
		file_manager = 'ranger',
		-- Default media player
		multimedia = 'mpv',
		-- Default game, can be a launcher like steam
		game = '',
		-- Default graphics editor
		graphics = '',
		-- Default sandbox
		sandbox = '',
		-- Default IDE
		development = 'nvim',
		-- Default network manager
		network_manager = '',
		-- Default bluetooth manager
		bluetooth_manager = 'blueman-manager',
		-- Default power manager
		power_manager = '',
		-- Default GUI package manager
		package_manager = '',
		-- Default locker
		lock = 'awesome-client "awesome.emit_signal(\'module::lockscreen_show\')"',
		-- Default quake terminal
		quake = '',
		-- Run menu
		rofi_runmenu = 'rofi -dpi ' .. screen.primary.dpi ..
							' -show run -theme '.. config_dir ..
							'configuration/rofi/runmenu/rofi.rasi',
		-- Emoji menu
		rofi_emojimenu = 'rofi -dpi ' .. screen.primary.dpi ..
							' -show emoji -modi emoji -theme '.. config_dir ..
							'configuration/rofi/emojimenu/rofi.rasi',
		-- App menu
		rofi_appmenu = 'rofi -dpi ' .. screen.primary.dpi ..
							' -show drun -theme ' .. config_dir ..
							'configuration/rofi/appmenu/rofi.rasi',

		-- Show time
		rofi_time = 'rofi -dpi ' .. screen.primary.dpi ..
							' -theme ' .. config_dir ..
							'configuration/rofi/time/rofi.rasi',

        -- Show calc
        rofi_calc = 'rofi -dpi ' .. screen.primary.dpi ..
                            ' -theme ' .. config_dir ..
                            'configuration/rofi/calc/rofi.rasi' ..
                            ' -show calc -modi calc -no-show-match -no-sort' ..
                            ' -calc-command "echo -n \'{result}\' | xclip -sel clip"'
		-- You can add more default applications here
	},

	-- List of apps to start once on start-up
	run_on_start_up = {
		-- Compositor
		'picom -b --dbus --config ' ..
		config_dir .. 'configuration/picom.conf',
        -- Network applet
        'nm-applet',
		-- Blueman applet
		'blueman-applet',
		-- Music server
		-- Polkit and keyring
		'/usr/bin/lxqt-policykit-agent &',
		-- '/usr/bin/lxqt-policykit-agent &' ..
		-- ' eval $(gnome-keyring-daemon -s --components=gpg)',
        -- Set monitors dpi
        config_dir .. 'utilities/setup-monitors',
		-- Set the dpi for GDK applications
		'xrdb -merge ~/.Xresources',
		-- Audio equalizer
        -- Enable blue light filter
		'redshift -l 0:0 -t 4500:4500 -r &>/dev/null &',
        -- Auto screen look
        'systemctl --user reload-or-restart --now xidlehook.service',
        -- Darkman
        -- 'systemctl reload-or-restart --now geoclue.service',
        'systemctl --user reload-or-restart --now darkman.service',
        -- 'killall darkman; ' ..
        -- 'XDG_DATA_DIRS=~/.config/darkman ' ..
        -- 'darkman run > ~/.cache/awesome/darkman.log 2>&1 &',
        -- 'systemctl reload-or-restart geoclue.service',
        -- Use `xinput list` command to get touchpad device name
        -- `SynPS/2 Synaptics TouchPad` in this case
        -- 'xinput set-prop "SynPS/2 Synaptics TouchPad" "libinput Tapping Enabled" 1',
        -- Start imapnotify
        --'systemctl --user reload-or-restart goimapnotify.service',
        'killall -9 goimapnotify; ' ..
        'goimapnotify -conf ~/.config/imapnotify/imapnotify.conf ' ..
        '> ~/.cache/awesome/imapnotify.log 2>&1 &',
        '~/.config/imapnotify/notify.sh',
        -- Sleep hook to update wallpaper when coming back from sleep
        config_dir .. 'utilities/suspend-hook.py &',
        -- Start volctl
        config_dir .. 'utilities/volctl &',
        -- Start playerctl daemon
        'playerctld daemon'
	},

	-- List of binaries/shell scripts that will execute for a certain task
	utils = {
		-- Fullscreen screenshot
		full_screenshot = utils_dir .. 'snap full',
		-- Area screenshot
		area_screenshot = utils_dir .. 'snap area',
		-- Update profile picture
		update_profile  = utils_dir .. 'profile-image',
		-- Show time with rofi
		show_time  = utils_dir .. 'time'
	}
}

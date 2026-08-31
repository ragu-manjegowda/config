local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local filesystem = gears.filesystem
local config_dir = filesystem.get_configuration_dir()
local dpi = beautiful.xresources.apply_dpi
local apps = require('configuration.apps')
local widget_icon_dir = config_dir .. 'configuration/user-profile/'
local config = require('configuration.config')
local suspension = require('library.notification-suspension')
local fingerprint = require('module.lockscreen-fingerprint')

require('module.dynamic-wallpaper')
require('module.auto-start')
require('module.exit-screen')

-- Add paths to package.cpath
package.cpath = package.cpath .. ';' .. config_dir .. '/library/?.so;' .. '/usr/lib/lua-pam/?.so;'

-- Configuration table
local locker_config = {
    -- Clock mode
    military_clock = config.module.lockscreen.military_clock or false,
    -- Fallback password
    fallback_password = function()
        return config.module.lockscreen.fallback_password or 'toor'
    end,
    -- Capture a picture using webcam
    capture_intruder = config.module.lockscreen.capture_intruder or false,
    fingerprint_unlock = config.module.lockscreen.fingerprint_unlock == true,
    -- Save location, auto creates
    face_capture_dir = config.module.lockscreen.face_capture_dir or '$HOME/Pictures/Intruders/',
    -- Blur background
    blur_background = config.module.lockscreen.blur_background or false,
    -- Background directory
    bg_dir = config.module.lockscreen.bg_dir or (config_dir .. 'theme/wallpapers/'),
    -- Default background
    -- bg_image = config.module.lockscreen.bg_image or 'morning-wallpaper.jpg',
    -- /tmp directory
    tmp_wall_dir = config.module.lockscreen.tmp_wall_dir or
        ('/tmp/awesomewm/' .. (os.getenv('USER') or 'unknown') .. '/')
}
local lock_state_file = (os.getenv('XDG_RUNTIME_DIR') or locker_config.tmp_wall_dir) ..
    '/awesome-lockscreen.locked'

local function set_lock_state(locked)
    if not locked then
        os.remove(lock_state_file)
        return
    end

    local file = io.open(lock_state_file, 'w')
    if file then
        file:write('locked\n')
        file:close()
    end
end

local function is_lock_state_set()
    local file = io.open(lock_state_file, 'r')
    if not file then
        return false
    end

    file:close()
    return true
end

-- Useful variables (DO NOT TOUCH THESE)
local input_password = nil
local lock_again = nil
local type_again = true
local capture_now = locker_config.capture_intruder
local capture_in_progress = false
local locked_tag = nil
local client_focused = nil
local pam_module_loaded = false
local pam_module = nil
local current_user_name = '$USER'
local current_profile_image = widget_icon_dir .. 'default.svg'
local fingerprint_auth = nil
local locked_media_signals = {
    XF86MonBrightnessUp = 'widget::brightness',
    XF86MonBrightnessDown = 'widget::brightness',
    XF86AudioRaiseVolume = 'widget::volume',
    XF86AudioLowerVolume = 'widget::volume',
    XF86AudioMute = 'widget::volume',
    XF86AudioMicMute = 'widget::microphone'
}

local function refresh_locked_media_osd(key)
    local signal = locked_media_signals[key]
    if not signal then return false end

    gears.timer.start_new(0.15, function()
        awesome.emit_signal(signal, true)
        if signal == 'widget::microphone' then
            awesome.emit_signal('module::mic_osd:show', true)
        end
        return false
    end)
    return true
end

awesome.connect_signal('module::fingerprint_start', function()
    if fingerprint_auth then fingerprint_auth:start() end
end)

awesome.connect_signal('module::fingerprint_stop', function()
    if fingerprint_auth then fingerprint_auth:stop() end
end)

awesome.connect_signal('exit', function()
    if fingerprint_auth then fingerprint_auth:stop() end
end)

local function lockscreen_for_screen(s)
    if not s.valid then
        return nil
    end

    return s.lockscreen or s.lockscreen_extended
end

local function load_pam_module()
    if pam_module_loaded then
        return pam_module
    end

    pam_module_loaded = true
    local ok, module = pcall(require, 'liblua_pam')
    if ok and module and type(module.auth_current_user) == 'function' then
        pam_module = module
    end

    return pam_module
end

local function authenticate_with_pam(password)
    local module = load_pam_module()
    if not module then
        return nil
    end

    local ok, authenticated = pcall(function()
        return module:auth_current_user(password)
    end)

    if not ok then
        return nil
    end

    return authenticated == true
end

local function authenticate_password(password)
    if not password or password == '' then
        return false
    end

    local authenticated = authenticate_with_pam(password)
    if authenticated ~= nil then
        return authenticated
    end

    return password == locker_config.fallback_password()
end

local uname_text = wibox.widget {
    id = 'uname_text',
    markup = '$USER',
    font = beautiful.font_bold(18),
    align = 'center',
    valign = 'center',
    widget = wibox.widget.textbox
}

local caps_text = wibox.widget {
    id = 'uname_text',
    markup = 'Caps Lock is on',
    font = beautiful.font_italic(18),
    align = 'center',
    valign = 'center',
    opacity = 0.0,
    widget = wibox.widget.textbox
}

local caps_text_widget = wibox.widget {
    -- bg = beautiful.accent,
    widget = wibox.container.background,
    caps_text
}

local fingerprint_text = wibox.widget {
    text = 'Touch fingerprint sensor or enter password',
    font = beautiful.font_regular(14),
    align = 'center',
    valign = 'center',
    visible = locker_config.fingerprint_unlock,
    widget = wibox.widget.textbox
}

local fingerprint_text_widget = wibox.widget {
    bg = beautiful.bg_normal,
    widget = wibox.container.background,
    fingerprint_text
}

local function set_fingerprint_text(text)
    fingerprint_text:set_text(text)
    awesome.emit_signal('module::lockscreen_fingerprint_text', text)
end

local profile_imagebox = wibox.widget {
    id = 'user_icon',
    image = widget_icon_dir .. 'default.svg',
    resize = true,
    forced_height = dpi(130),
    forced_width = dpi(130),
    clip_shape = gears.shape.circle,
    widget = wibox.widget.imagebox
}

local clock_format = string.format('<span font="%s">%%A %%B %%d, %%H:%%M</span>', beautiful.font_bold(26))
if not locker_config.military_clock then
    clock_format = string.format('<span font="%s">%%A %%B %%d, %%I:%%M %%p</span>', beautiful.font_bold(26))
end

-- Create clock widget
local time = wibox.widget.textclock(clock_format, 60)

local wanted_text = wibox.widget {
    markup = 'INTRUDER ALERT!',
    font   = beautiful.font_bold(14),
    align  = 'center',
    valign = 'center',
    widget = wibox.widget.textbox
}

local msg_table = {
    'This incident will be reported.',
    'We are watching you.',
    'We know where you live.',
    'RUN!',
    'Yamete, Oniichan~ uwu',
    'This will self-destruct in 5 seconds!',
    'Image successfully sent!',
    'You\'re doomed!',
    'Authentication failed!',
    'I am watching you.',
    'I know where you live.',
    'RUN!',
    'Your parents must be proud of you.'
}

local wanted_msg = wibox.widget {
    markup = 'This incident will be reported!',
    font   = beautiful.font_regular(12),
    align  = 'center',
    valign = 'center',
    widget = wibox.widget.textbox
}

local wanted_image = wibox.widget {
    image         = widget_icon_dir .. 'default.svg',
    resize        = true,
    forced_height = dpi(120),
    clip_shape    = gears.shape.rounded_rect,
    widget        = wibox.widget.imagebox
}

local circle_container = wibox.widget {
    bg = beautiful.transparent,
    forced_width = dpi(140),
    forced_height = dpi(140),
    shape = gears.shape.circle,
    widget = wibox.container.background
}

local locker_arc = wibox.widget {
    bg = beautiful.transparent,
    forced_width = dpi(140),
    forced_height = dpi(140),
    shape = function(cr, width, height)
        gears.shape.arc(cr, width, height, dpi(5), 0, (math.pi / 2), false, false)
    end,
    widget = wibox.container.background
}

local rotate_container = wibox.container.rotate()
local locker_widget = wibox.widget {
    {
        locker_arc,
        widget = rotate_container
    },
    layout = wibox.layout.fixed.vertical
}

-- Rotation direction table
local rotation_direction = { 'north', 'west', 'south', 'east' }

-- Red, Green, Yellow, Blue
local red = beautiful.system_red_light
local green = beautiful.system_green_light
local yellow = beautiful.system_yellow_light
local blue = beautiful.system_blue_light

-- Color table
local arc_color = { red, green, yellow, blue }

-- Processes
local locker = function(s)
    local lockscreen = wibox {
        screen = s,
        visible = false,
        ontop = true,
        type = 'splash',
        width = s.geometry.width,
        height = s.geometry.height,
        bg = beautiful.bg_focus,
        fg = beautiful.fg_normal
    }

    -- Update username textbox
    awful.spawn.easy_async_with_shell(
        [[
		fullname="$(getent passwd `whoami` | cut -d ':' -f 5 | cut -d ',' -f 1 | tr -d "\n")"
		if [ -z "$fullname" ];
		then
			printf "$(whoami)@$(uname -n)"
		else
			printf "$fullname"
		fi
		]],
        function(stdout)
            stdout = stdout:gsub('%\n', '')
            current_user_name = stdout
            uname_text:set_markup(stdout)
            awesome.emit_signal('module::lockscreen_user_name', stdout)
        end
    )

    local update_profile_pic = function()
        awful.spawn.easy_async_with_shell(
            apps.utils.update_profile,
            function(stdout)
                stdout = stdout:gsub('%\n', '')
                if not stdout:match('default') then
                    current_profile_image = stdout
                    profile_imagebox:set_image(stdout)
                    awesome.emit_signal('module::lockscreen_profile_image', stdout)
                else
                    local default_image = widget_icon_dir .. 'default.svg'
                    current_profile_image = default_image
                    profile_imagebox:set_image(default_image)
                    awesome.emit_signal('module::lockscreen_profile_image', default_image)
                end
            end
        )
    end

    -- Update image
    gears.timer.start_new(
        2,
        function()
            update_profile_pic()
        end
    )

    local wanted_poster = awful.popup {
        widget = {
            {
                {
                    wanted_text,
                    {
                        nil,
                        wanted_image,
                        nil,
                        expand = 'none',
                        layout = wibox.layout.align.horizontal
                    },
                    wanted_msg,
                    spacing = dpi(5),
                    layout = wibox.layout.fixed.vertical
                },
                margins = dpi(20),
                widget = wibox.container.margin
            },
            bg = beautiful.background,
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background
        },
        bg = beautiful.transparent,
        type = 'utility',
        ontop = true,
        shape = gears.shape.rectangle,
        maximum_width = dpi(250),
        maximum_height = dpi(250),
        hide_on_right_click = false,
        preferred_anchors = { 'middle' },
        visible = false
    }

    -- Place wanted poster at the bottom of primary screen
    awful.placement.top(
        wanted_poster,
        {
            margins = {
                top = dpi(10)
            }
        }
    )

    -- Check Capslock state
    local check_caps = function()
        awful.spawn.easy_async_with_shell(
            'xset q | grep Caps | cut -d: -f3 | cut -d0 -f1 | tr -d \' \'',
            function(stdout)
                local caps_on = stdout:match('on') ~= nil
                if caps_on then
                    caps_text.opacity = 1.0
                    caps_text_widget.bg = beautiful.accent
                else
                    caps_text.opacity = 0.0
                    caps_text_widget.bg = beautiful.transparent
                end
                caps_text:emit_signal('widget::redraw_needed')
                awesome.emit_signal('module::lockscreen_caps_state', caps_on)
            end
        )
    end

    -- Rotate the color arc on random direction
    local locker_arc_rotate = function()
        local direction = rotation_direction[math.random(#rotation_direction)]
        local color = arc_color[math.random(#arc_color)]

        rotate_container.direction = direction
        locker_arc.bg = color

        rotate_container:emit_signal('widget::redraw_needed')
        locker_arc:emit_signal('widget::redraw_needed')
        locker_widget:emit_signal('widget::redraw_needed')
        awesome.emit_signal('module::lockscreen_ring_feedback', direction, color)
    end

    -- Check webcam
    local check_webcam = function()
        awful.spawn.easy_async_with_shell(
            'ls -l /dev/video* | grep ' .. config.module.lockscreen.camera_device,
            function(stdout)
                if not locker_config.capture_intruder then
                    capture_now = false
                    return
                end

                if not stdout:match(config.module.lockscreen.camera_device) then
                    capture_now = false
                else
                    capture_now = true
                end
            end
        )
    end

    check_webcam()

    -- Snap an image of the intruder
    local intruder_capture = function()
        if capture_in_progress then return end
        capture_in_progress = true
        local capture_image = [[
        set -eu
        save_dir="]] .. locker_config.face_capture_dir .. [["
        date="$(date +%Y%m%d_%H%M%S)"
        file_loc="${save_dir}SUSPECT-${date}.png"

        if [ ! -d "$save_dir" ]; then
            mkdir -p "$save_dir";
        fi

        if ]] .. config.module.lockscreen.capture_script ..
            " " .. config.module.lockscreen.camera_device .. [[ "${file_loc}"; then
            canberra-gtk-play -i camera-shutter 2>/dev/null &
            echo "${file_loc}"
        else
            rm -f "${file_loc}"
            exit 1
        fi
        ]]

        -- Capture the filthy intruder face
        awful.spawn.easy_async_with_shell(
            capture_image,
            function(stdout, _, _, exit_code)
                capture_in_progress = false
                if exit_code ~= 0 or stdout == '' then return end

                -- Humiliate the intruder by showing his/her hideous face
                wanted_image:set_image(stdout:gsub('%s+$', ''))
                wanted_msg:set_markup(msg_table[math.random(#msg_table)])
                wanted_poster.visible = true

                awful.placement.top(
                    wanted_poster,
                    {
                        margins = {
                            top = dpi(10)
                        }
                    }
                )

                wanted_image:emit_signal('widget::redraw_needed')
            end
        )
    end

    local password_grabber
    local auth_succeeded = false

    local reset_failed_auth = function()
        gears.timer.start_new(
            1,
            function()
                circle_container.bg = beautiful.transparent
                awesome.emit_signal('module::lockscreen_auth_feedback', beautiful.transparent)
                type_again = true
                if locker_config.fingerprint_unlock then
                    set_fingerprint_text('Touch fingerprint sensor or enter password')
                end
            end
        )
    end

    -- Login failed
    local stoprightthereyoucriminalscum = function()
        if auth_succeeded then return end
        circle_container.bg = red
        awesome.emit_signal('module::lockscreen_auth_feedback', red)
        reset_failed_auth()
        if capture_now then intruder_capture() end
    end

    -- Login successful
    local generalkenobi_ohhellothere = function()
        if auth_succeeded then return end
        auth_succeeded = true
        if fingerprint_auth then fingerprint_auth:stop() end
        circle_container.bg = beautiful.accent
        awesome.emit_signal('module::lockscreen_auth_feedback', beautiful.accent)

        -- Add a little delay before unlocking completely
        gears.timer.start_new(
            1,
            function()
                if capture_now then
                    -- Hide wanted poster
                    wanted_poster.visible = false
                end

                -- Hide all the lockscreen on all screen
                ---@diagnostic disable-next-line: redefined-local
                for s in screen do
                    local target = lockscreen_for_screen(s)
                    if target then
                        target.visible = false
                    end
                end

                circle_container.bg = beautiful.transparent
                awesome.emit_signal('module::lockscreen_auth_feedback', beautiful.transparent)
                set_lock_state(false)
                lock_again = true
                type_again = true

                awesome.emit_signal('module::unlocked')

                suspension.set('lockscreen', false)

                -- Select old tag
                -- And restore minimized focused client if there's any
                if locked_tag then
                    locked_tag.selected = true
                    locked_tag = nil
                end

                if client_focused then
                    client_focused.minimized = false
                    client_focused:emit_signal('request::activate')
                    client_focused:raise()
                    client_focused = nil
                end
            end
        )
    end

    if fingerprint_auth then fingerprint_auth:stop() end
    if locker_config.fingerprint_unlock then
        fingerprint_auth = fingerprint.new {
            user = os.getenv('USER'),
            is_locked = is_lock_state_set,
            spawn = function(argv, callbacks)
                return awful.spawn.with_line_callback(argv, callbacks)
            end,
            kill = function(pid)
                awful.spawn({ 'kill', '-TERM', tostring(pid) })
            end,
            retry = function(callback)
                gears.timer.start_new(1, function()
                    callback()
                    return false
                end)
            end,
            on_match = function()
                if awful.keygrabber.current_instance == password_grabber then
                    password_grabber:stop()
                end
                generalkenobi_ohhellothere()
            end,
            on_no_match = function()
                set_fingerprint_text('Fingerprint not recognized; enter password')
                stoprightthereyoucriminalscum()
            end
        }
    else
        fingerprint_auth = nil
    end

    -- A backdoor.
    -- Sometimes I'm too lazy to type so I decided to create this.
    -- Sometimes my genius is... it's almost frightening.
    local back_door = function()
        generalkenobi_ohhellothere()
    end

    -- Password/key grabber
    password_grabber = awful.keygrabber {
        stop_event           = 'release',
        mask_event_callback  = true,
        keybindings          = {
            awful.key {
                modifiers = { 'Control' },
                key       = 'u',
                on_press  = function()
                    input_password = nil
                end
            },
            awful.key {
                modifiers = { 'Mod1', 'Mod4', 'Shift', 'Control' },
                key       = 'Return',
                on_press  = function(self)
                    if not type_again then
                        return
                    end

                    self:stop()
                    back_door()
                end
            }
        },
        keypressed_callback  = function(_, _, key, _)
            if refresh_locked_media_osd(key) then
                return
            end

            if not type_again then
                return
            end

            -- Clear input string
            if key == 'Escape' then
                -- Clear input threshold
                input_password = nil
                return
            end

            if key == 'BackSpace' then
                if input_password then
                    input_password = input_password:sub(1, -2)
                    if input_password == '' then
                        input_password = nil
                    end
                end
                locker_arc_rotate()
                return
            end

            -- Accept only the single charactered key
            -- Ignore 'Shift', 'Control', 'Return', 'F1', 'F2', etc., etc.
            if #key == 1 then
                locker_arc_rotate()

                if input_password == nil then
                    input_password = key
                    return
                end
                input_password = input_password .. key
            end
        end,
        keyreleased_callback = function(self, _, key, _)
            locker_arc.bg = beautiful.transparent
            locker_arc:emit_signal('widget::redraw_needed')
            awesome.emit_signal('module::lockscreen_ring_feedback', rotate_container.direction, beautiful.transparent)

            if key == 'Caps_Lock' then
                check_caps()
                return
            end

            if not type_again then
                return
            end

            -- Validation
            if key == 'Return' then
                -- Validate password
                local authenticated = authenticate_password(input_password)

                if authenticated then
                    -- Come in!
                    self:stop()
                    generalkenobi_ohhellothere()
                else
                    -- F*ck off, you [REDACTED]!
                    stoprightthereyoucriminalscum()
                end

                -- Allow typing again and empty password container
                type_again = false
                input_password = nil
            end
        end
    }

    local function ensure_password_grab()
        if awful.keygrabber.current_instance == password_grabber then
            return true
        end

        local current = awful.keygrabber.current_instance
        if current then
            current:stop()
        end

        password_grabber:start()
        return awful.keygrabber.current_instance == password_grabber
    end

    lockscreen:setup {
        layout = wibox.layout.align.vertical,
        expand = 'none',
        nil,
        {
            layout = wibox.layout.align.horizontal,
            expand = 'none',
            nil,
            {
                layout = wibox.layout.fixed.vertical,
                expand = 'none',
                spacing = dpi(20),
                {
                    {
                        layout = wibox.layout.align.horizontal,
                        expand = 'none',
                        nil,
                        {
                            bg     = beautiful.bg_normal,
                            widget = wibox.container.background,
                            time
                        },
                        nil
                    },
                    spacing = dpi(10),
                    expand = 'none',
                    layout = wibox.layout.fixed.vertical
                },
                {
                    spacing = dpi(10),
                    layout = wibox.layout.fixed.vertical,
                    {
                        circle_container,
                        locker_widget,
                        {
                            layout = wibox.layout.align.vertical,
                            expand = 'none',
                            nil,
                            {
                                layout = wibox.layout.align.horizontal,
                                expand = 'none',
                                nil,
                                profile_imagebox,
                                nil
                            },
                            nil,
                        },
                        layout = wibox.layout.stack
                    },
                    {
                        bg     = beautiful.bg_normal,
                        widget = wibox.container.background,
                    uname_text
                    },
                    fingerprint_text_widget,
                    caps_text_widget
                },
            },
            nil
        },
        nil
    }

    local show_lockscreen = function()
        -- Why is there a lock_again variable?
        -- It prevents the user to spam locking while in a process of authentication
        -- Prevents a potential bug/problem
        if lock_again == true or lock_again == nil then
            -- Force update clock widget
            time:emit_signal('widget::redraw_needed')

            -- Check capslock status
            check_caps()

            -- Check webcam status
            -- check_webcam()

            -- Show all the lockscreen on each screen
            ---@diagnostic disable-next-line: redefined-local
            for s in screen do
                local target = lockscreen_for_screen(s)
                if target then
                    target.visible = true
                end
            end

            input_password = nil
            type_again = true
            auth_succeeded = false
            lock_again = false
            set_lock_state(true)

            if not ensure_password_grab() then
                gears.timer.start_new(0.1, function()
                    if ensure_password_grab() then
                        suspension.set('lockscreen', true)
                        if fingerprint_auth then fingerprint_auth:start() end
                        awesome.emit_signal('module::locked')
                        return false
                    end
                    return true
                end)
                return
            end

            suspension.set('lockscreen', true)
            if fingerprint_auth then fingerprint_auth:start() end

            -- send signal to exit screen (needed during suspend)
            awesome.emit_signal('module::locked')
        end
    end

    local free_keygrab = function()
        -- Kill rofi instance.
        awful.spawn.with_shell('kill -9 $(pgrep rofi)')

        -- Check if there's a keygrabbing instance.
        -- If yes, stop it.
        local keygrabbing_instance = awful.keygrabber.current_instance
        if keygrabbing_instance then
            keygrabbing_instance:stop()
        end

        -- Unselect all tags and minimize the focused client
        -- These will fix the problem with virtualbox or
        -- any other program that has keygrabbing enabled
        if client.focus then
            client_focused = client.focus
            client.focus.minimized = true
        end
        for _, t in ipairs(mouse.screen.selected_tags) do
            locked_tag = t
            t.selected = false
        end
    end

    awesome.connect_signal(
        'module::lockscreen_show',
        function()
            if lock_again == true or lock_again == nil then
                free_keygrab()
                show_lockscreen()
            elseif is_lock_state_set() and ensure_password_grab() then
                if fingerprint_auth then fingerprint_auth:start() end
                awesome.emit_signal('module::locked')
            end
        end
    )

    awesome.connect_signal(
        'module::sleep_resumed',
        function()
            if fingerprint_auth then fingerprint_auth:stop() end
            awesome.emit_signal('module::spawn_apps')
            awesome.emit_signal('module::change_wallpaper')
            awesome.emit_signal('module::change_background_wallpaper')
            awful.spawn.with_shell('xset dpms force on; xset s reset; xset r rate 180 45')

            if is_lock_state_set() then
                ensure_password_grab()
                if fingerprint_auth then fingerprint_auth:start() end
            end
        end
    )
    return lockscreen
end

-- This lockscreen is for the extra/multi monitor
local locker_ext = function(s)
    local extended_lockscreen = wibox {
        screen = s,
        visible = false,
        ontop = true,
        type = 'splash',
        x = s.geometry.x,
        y = s.geometry.y,
        width = s.geometry.width,
        height = s.geometry.height,
        bg = beautiful.bg_focus,
        fg = beautiful.fg_normal
    }

    local ext_uname_text = wibox.widget {
        markup = current_user_name,
        font = beautiful.font_bold(18),
        align = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    }

    local ext_caps_text = wibox.widget {
        markup = 'Caps Lock is on',
        font = beautiful.font_italic(18),
        align = 'center',
        valign = 'center',
        opacity = 0.0,
        widget = wibox.widget.textbox
    }

    local ext_caps_text_widget = wibox.widget {
        widget = wibox.container.background,
        ext_caps_text
    }

    local ext_fingerprint_text = wibox.widget {
        text = 'Touch fingerprint sensor or enter password',
        font = beautiful.font_regular(14),
        align = 'center',
        valign = 'center',
        visible = locker_config.fingerprint_unlock,
        widget = wibox.widget.textbox
    }

    local ext_fingerprint_text_widget = wibox.widget {
        bg = beautiful.bg_normal,
        widget = wibox.container.background,
        ext_fingerprint_text
    }

    local ext_profile_imagebox = wibox.widget {
        image = current_profile_image,
        resize = true,
        forced_height = dpi(130),
        forced_width = dpi(130),
        clip_shape = gears.shape.circle,
        widget = wibox.widget.imagebox
    }

    local ext_circle_container = wibox.widget {
        bg = beautiful.transparent,
        forced_width = dpi(140),
        forced_height = dpi(140),
        shape = gears.shape.circle,
        widget = wibox.container.background
    }

    local ext_locker_arc = wibox.widget {
        bg = beautiful.transparent,
        forced_width = dpi(140),
        forced_height = dpi(140),
        shape = function(cr, width, height)
            gears.shape.arc(cr, width, height, dpi(5), 0, (math.pi / 2), false, false)
        end,
        widget = wibox.container.background
    }

    local ext_rotate_container = wibox.container.rotate()
    local ext_locker_widget = wibox.widget {
        {
            ext_locker_arc,
            widget = ext_rotate_container
        },
        layout = wibox.layout.fixed.vertical
    }

    local ext_time = wibox.widget.textclock(clock_format, 60)

    local is_active = function()
        return extended_lockscreen.valid
    end

    local signal_handlers = {}
    local function connect_signal(name, handler)
        awesome.connect_signal(name, handler)
        signal_handlers[#signal_handlers + 1] = { name, handler }
    end

    connect_signal(
        'module::lockscreen_user_name',
        function(name)
            if not is_active() then return end
            ext_uname_text:set_markup(name)
        end
    )

    connect_signal(
        'module::lockscreen_profile_image',
        function(image)
            if not is_active() then return end
            ext_profile_imagebox:set_image(image)
        end
    )

    connect_signal(
        'module::lockscreen_ring_feedback',
        function(direction, color)
            if not is_active() then return end
            ext_rotate_container.direction = direction
            ext_locker_arc.bg = color
            ext_rotate_container:emit_signal('widget::redraw_needed')
            ext_locker_arc:emit_signal('widget::redraw_needed')
            ext_locker_widget:emit_signal('widget::redraw_needed')
        end
    )

    connect_signal(
        'module::lockscreen_auth_feedback',
        function(color)
            if not is_active() then return end
            ext_circle_container.bg = color
            ext_circle_container:emit_signal('widget::redraw_needed')
        end
    )

    connect_signal(
        'module::lockscreen_fingerprint_text',
        function(text)
            if not is_active() then return end
            ext_fingerprint_text:set_text(text)
        end
    )

    connect_signal(
        'module::lockscreen_caps_state',
        function(caps_on)
            if not is_active() then return end
            if caps_on then
                ext_caps_text.opacity = 1.0
                ext_caps_text_widget.bg = beautiful.accent
            else
                ext_caps_text.opacity = 0.0
                ext_caps_text_widget.bg = beautiful.transparent
            end
            ext_caps_text:emit_signal('widget::redraw_needed')
        end
    )

    local removed_handler
    removed_handler = function(removed)
        if removed ~= s then
            return
        end
        for _, signal in ipairs(signal_handlers) do
            awesome.disconnect_signal(signal[1], signal[2])
        end
        screen.disconnect_signal('removed', removed_handler)
    end
    screen.connect_signal('removed', removed_handler)

    extended_lockscreen:setup {
        layout = wibox.layout.align.vertical,
        expand = 'none',
        nil,
        {
            layout = wibox.layout.align.horizontal,
            expand = 'none',
            nil,
            {
                layout = wibox.layout.fixed.vertical,
                expand = 'none',
                spacing = dpi(20),
                {
                    {
                        layout = wibox.layout.align.horizontal,
                        expand = 'none',
                        nil,
                        {
                            bg = beautiful.bg_normal,
                            widget = wibox.container.background,
                            ext_time
                        },
                        nil
                    },
                    spacing = dpi(10),
                    expand = 'none',
                    layout = wibox.layout.fixed.vertical
                },
                {
                    spacing = dpi(10),
                    layout = wibox.layout.fixed.vertical,
                    {
                        ext_circle_container,
                        ext_locker_widget,
                        {
                            layout = wibox.layout.align.vertical,
                            expand = 'none',
                            nil,
                            {
                                layout = wibox.layout.align.horizontal,
                                expand = 'none',
                                nil,
                                ext_profile_imagebox,
                                nil
                            },
                            nil
                        },
                        layout = wibox.layout.stack
                    },
                    {
                        bg = beautiful.bg_normal,
                        widget = wibox.container.background,
                        ext_uname_text
                    },
                    ext_fingerprint_text_widget,
                    ext_caps_text_widget
                }
            },
            nil
        },
        nil
    }

    return extended_lockscreen
end

-- Create lockscreen for each screen
local create_lock_screens = function(s)
    if s.index == 1 then
        s.lockscreen = locker(s)
    else
        s.lockscreen_extended = locker_ext(s)
    end
end

-- Filter background image
local filter_bg_image = function(wall_name, index, ap, width, height)
    -- Checks if the blur has to be blurred
    local blur_filter_param = ''
    if locker_config.blur_background then
        blur_filter_param = '-filter Gaussian -blur 0x10'
    end

    -- Create imagemagick command
    local magic = [[
	sh -c "
	if [ ! -d ]] .. locker_config.tmp_wall_dir .. [[ ];
	then
		mkdir -p ]] .. locker_config.tmp_wall_dir .. [[;
	fi
	convert -quality 100 -brightness-contrast -20x0 ]] ..
        ' ' .. blur_filter_param .. ' ' .. locker_config.bg_dir .. wall_name ..
        [[ -gravity center -crop ]] .. ap .. [[:1 +repage -resize ]] .. width .. 'x' .. height ..
        [[! ]] .. locker_config.tmp_wall_dir .. index .. wall_name .. [[
	"]]
    return magic
end

-- Apply lockscreen background image
local apply_ls_bg_image = function(wall_name)
    -- Iterate through all the screens and create a lockscreen for each of it
    for s in screen do
        local index = s.index .. '-'

        -- Get screen geometry
        local screen_width = s.geometry.width
        local screen_height = s.geometry.height

        -- Get the right resolution/aspect ratio that will be use as the background
        local aspect_ratio = screen_width / screen_height
        aspect_ratio = math.floor(aspect_ratio * 100) / 100

        -- Create image filter command
        local cmd = nil
        cmd = filter_bg_image(wall_name, index, aspect_ratio, screen_width, screen_height)

        local target = lockscreen_for_screen(s)
        if target then
            awful.spawn.easy_async_with_shell(
                cmd,
                function()
                    if target == lockscreen_for_screen(s) then
                        target.bgimage = locker_config.tmp_wall_dir .. index .. wall_name
                    end
                end
            )
        end
    end
end

awesome.connect_signal(
    'module::change_background_wallpaper',
    function()
        -- Update lockscreen wallpaper
        -- Defined in dynamic-wallpaper.lua
        apply_ls_bg_image(get_wallpaper_name())
    end
)

-- Create a lockscreen and its background for each screen on start-up
screen.connect_signal(
    'request::desktop_decoration',
    function(s)
        create_lock_screens(s)
        -- Defined in dynamic-wallpaper.lua
        apply_ls_bg_image(get_wallpaper_name())
        if s.index == 1 and is_lock_state_set() then
            gears.timer.delayed_call(function()
                awesome.emit_signal('module::lockscreen_show')
            end)
        end
    end
)

screen.connect_signal(
    'removed',
    function()
        gears.timer.delayed_call(function()
            apply_ls_bg_image(get_wallpaper_name())
        end)
    end
)

local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local naughty = require('naughty')
local beautiful = require('beautiful')
local filesystem = gears.filesystem
local config_dir = filesystem.get_configuration_dir()
local dpi = beautiful.xresources.apply_dpi
local apps = require('configuration.apps')
local widget_icon_dir = config_dir .. 'configuration/user-profile/'
local config = require('configuration.config')

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

-- Useful variables (DO NOT TOUCH THESE)
local input_password = nil
local lock_again = nil
local type_again = true
local capture_now = locker_config.capture_intruder
local locked_tag = nil
local client_focused = nil
local MAX_RESUMED_NOTIFICATIONS = 10
local pam_module_loaded = false
local pam_module = nil
local current_user_name = '$USER'
local current_profile_image = widget_icon_dir .. 'default.svg'

local function destroy_notification(notification)
    local reason = naughty.notification_closed_reason and
        naughty.notification_closed_reason.expired or 1
    naughty.destroy(notification, reason)
end

local function trim_pending_notifications_for_resume()
    local queued = {}

    for _, notification in ipairs(naughty.notifications or {}) do
        table.insert(queued, notification)
    end

    for index = MAX_RESUMED_NOTIFICATIONS + 1, #queued do
        destroy_notification(queued[index])
    end
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
        local capture_image = [[
        save_dir="]] .. locker_config.face_capture_dir .. [["
        date="$(date +%Y%m%d_%H%M%S)"
        file_loc="${save_dir}SUSPECT-${date}.png"

        if [ ! -d "$save_dir" ]; then
            mkdir -p "$save_dir";
        fi

        ]] .. config.module.lockscreen.capture_script ..
            " " .. config.module.lockscreen.camera_device .. [[ "${file_loc}"

        canberra-gtk-play -i camera-shutter 2>/dev/null &
        echo "${file_loc}"
        ]]

        -- Capture the filthy intruder face
        awful.spawn.easy_async_with_shell(
            capture_image,
            function(stdout)
                circle_container.bg = beautiful.transparent
                awesome.emit_signal('module::lockscreen_auth_feedback', beautiful.transparent)

                -- Humiliate the intruder by showing his/her hideous face
                wanted_image:set_image(stdout:gsub('%\n', ''))
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
                type_again = true
            end
        )
    end

    -- Login failed
    local stoprightthereyoucriminalscum = function()
        circle_container.bg = red
        awesome.emit_signal('module::lockscreen_auth_feedback', red)
        if capture_now then
            intruder_capture()
        else
            gears.timer.start_new(
                1,
                function()
                    circle_container.bg = beautiful.transparent
                    awesome.emit_signal('module::lockscreen_auth_feedback', beautiful.transparent)
                    type_again = true
                end
            )
        end
    end

    -- Login successful
    local generalkenobi_ohhellothere = function()
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
                    if s.index == 1 then
                        s.lockscreen.visible = false
                    else
                        s.lockscreen_extended.visible = false
                    end
                end

                circle_container.bg = beautiful.transparent
                awesome.emit_signal('module::lockscreen_auth_feedback', beautiful.transparent)
                lock_again = true
                type_again = true

                awesome.emit_signal('module::unlocked')

                -- Do not resume notifications if dont_disturb_state mode is on
                -- Or if the info_center is visible
                local focused = awful.screen.focused()
                if not (_G.dont_disturb_state or (focused.info_center and focused.info_center.visible)) then
                    trim_pending_notifications_for_resume()
                    naughty.suspended = false
                end

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
    -- A backdoor.
    -- Sometimes I'm too lazy to type so I decided to create this.
    -- Sometimes my genius is... it's almost frightening.
    local back_door = function()
        generalkenobi_ohhellothere()
    end

    -- Password/key grabber
    local password_grabber = awful.keygrabber {
        auto_start           = true,
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
                    caps_text_widget
                },
            },
            nil
        },
        nil
    }

    -- Exit screen sends this signal when sleep is resumed
    awesome.connect_signal(
        'module::sleep_resumed',
        function()
            awesome.emit_signal('module::spawn_apps')
            awesome.emit_signal('module::change_wallpaper')
            awesome.emit_signal('module::change_background_wallpaper')
            awful.spawn.with_shell('xset r rate 180 45')
        end
    )

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
                if s.index == 1 then
                    s.lockscreen.visible = true
                else
                    s.lockscreen_extended.visible = true
                end
            end

            -- Start keygrabbing, but with a little delay to
            -- give some extra time for the free_keygrab function
            gears.timer.start_new(
                0.5,
                function()
                    -- Start key grabbing for password
                    password_grabber:start()
                end
            )

            -- Dont lock again
            lock_again = false

            -- Do not suspend notifications if dont_disturb_state mode is on
            -- Or if the info_center is visible
            local focused = awful.screen.focused()
            if not (_G.dont_disturb_state or (focused.info_center and focused.info_center.visible)) then
                -- naughty.destroy_all_notifications(nil, 1)
                naughty.suspended = true
            end

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

    awesome.connect_signal(
        'module::lockscreen_user_name',
        function(name)
            if not is_active() then return end
            ext_uname_text:set_markup(name)
        end
    )

    awesome.connect_signal(
        'module::lockscreen_profile_image',
        function(image)
            if not is_active() then return end
            ext_profile_imagebox:set_image(image)
        end
    )

    awesome.connect_signal(
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

    awesome.connect_signal(
        'module::lockscreen_auth_feedback',
        function(color)
            if not is_active() then return end
            ext_circle_container.bg = color
            ext_circle_container:emit_signal('widget::redraw_needed')
        end
    )

    awesome.connect_signal(
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

-- Don't show notification popups if the screen is locked
local check_lockscreen_visibility = function()
    local focused = awful.screen.focused()
    if focused.lockscreen and focused.lockscreen.visible then
        return true
    end
    if focused.lockscreen_extended and focused.lockscreen_extended.visible then
        return true
    end
    return false
end

-- Notifications signal
-- Check for added since we are doing suspended instead of destroy_all_notifications
naughty.connect_signal(
    'added',
    function(_)
        if check_lockscreen_visibility() then
            -- Do not suspend notifications if dont_disturb_state mode is on
            -- Or if the info_center is visible
            local focused = awful.screen.focused()
            if not (_G.dont_disturb_state or (focused.info_center and focused.info_center.visible)) then
                -- naughty.destroy_all_notifications(nil, 1)
                naughty.suspended = true
            end
        end
    end
)

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

        -- Asign lockscreen to each screen
        if s.index == 1 then
            -- Primary screen
            awful.spawn.easy_async_with_shell(
                cmd,
                function()
                    s.lockscreen.bgimage = locker_config.tmp_wall_dir .. index .. wall_name
                end
            )
        else
            -- Multihead screen/s
            awful.spawn.easy_async_with_shell(
                cmd,
                function()
                    s.lockscreen_extended.bgimage = locker_config.tmp_wall_dir .. index .. wall_name
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
    end
)

-- Regenerate lockscreens and its background if a screen was removed to avoid errors
screen.connect_signal(
    'removed',
    function(s)
        create_lock_screens(s)
        -- Defined in dynamic-wallpaper.lua
        apply_ls_bg_image(get_wallpaper_name())
    end
)

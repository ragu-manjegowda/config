-- MODULE AUTO-START
-- Run all the apps listed in configuration/apps.lua as run_on_start_up only once when awesome start

local awful = require('awful')
local naughty = require('naughty')
local apps = require('configuration.apps')
local config = require('configuration.config')
local debug_mode = config.module.auto_start.debug_mode or false

local run_once = function(cmd)
    local findme = cmd
    local firstspace = cmd:find(' ')
    if firstspace then
        findme = cmd:sub(0, firstspace - 1)
    end
    awful.spawn.easy_async_with_shell(
        string.format('pgrep -f -u $USER -x %s > /dev/null || (%s)', findme, cmd),
        function(_, stderr)
            -- Debugger
            if not stderr or stderr == '' or not debug_mode then
                return
            end
            naughty.notification({
                app_name = 'Start-up Applications',
                title = '<b>Oof! Error detected when starting ' .. cmd .. '!</b>',
                message = stderr:gsub('%\n', ''),
                icon = require('beautiful').awesome_icon
            })
        end
    )
end

awesome.connect_signal(
    'module::spawn_apps',
    function()
        -- Need the following when we come back from sleep
        -- run_once('systemctl reload-or-restart --now geoclue.service')
        -- run_once('killall darkman; ' ..
        -- 'XDG_DATA_DIRS=~/.config/darkman ' ..
        -- 'darkman run > ~/.cache/awesome/darkman.log 2>&1 &')
        run_once('killall -9 goimapnotify; ' ..
            'goimapnotify -conf ~/.config/imapnotify/imapnotify.conf ' ..
            '> ~/.cache/awesome/imapnotify.log 2>&1 &')

        -- No need for this since they are now part of start-up apps
        -- Just a fail safe mechanism in case user services fails
        run_once('systemctl --user reload-or-restart --now darkman.service')
        -- awful.spawn('systemctl --user reload-or-restart --now goimapnotify.service')

        -- Update email's list when we come back from sleep
        run_once('~/.config/imapnotify/notify.sh')
    end
)

for _, app in ipairs(apps.run_on_start_up) do
    run_once(app)
end

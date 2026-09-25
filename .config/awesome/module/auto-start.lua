-- MODULE AUTO-START
-- Run all the apps listed in configuration/apps.lua as run_on_start_up only once when awesome start

local awful = require('awful')
local naughty = require('naughty')
local apps = require('configuration.apps')
local config = require('configuration.config')
local debug_mode = config.module.auto_start.debug_mode or false
local auto_start_disabled = os.getenv('AWESOME_SKIP_AUTOSTART') == '1'

-- Only long-lived programs need process checks. Setup commands must run on
-- each Awesome start; taking their first word as a pgrep pattern suppresses
-- unrelated commands and does not identify their resulting processes.
local processes = {
    picom = { '-x', 'picom' },
    xiccd = { '-x', 'xiccd' },
    ['nm-applet'] = { '-x', 'nm-applet' },
    ['blueman-applet'] = { '-x', 'blueman-applet' },
}

local run_once = function(cmd)
    if cmd:match('^systemctl%s') then
        awful.spawn.with_shell(cmd)
        return
    end

    local executable = cmd:match('^%s*(%S+)')
    local process = processes[executable]
    if executable == '/usr/bin/lxqt-policykit-agent' or
        (executable and executable:match('/suspend%-hook%.py$')) then
        process = { '-f', executable }
    end

    if not process then
        awful.spawn.with_shell(cmd)
        return
    end

    local pgrep_args = { 'pgrep', process[1] }
    local user = os.getenv('USER') or os.getenv('LOGNAME')
    if user and user ~= '' then
        pgrep_args[#pgrep_args + 1] = '-u'
        pgrep_args[#pgrep_args + 1] = user
    end
    pgrep_args[#pgrep_args + 1] = process[2]

    awful.spawn.easy_async(
        pgrep_args,
        function(_, stderr, _, exit_code)
            if exit_code ~= 0 then
                awful.spawn.with_shell(cmd)
            elseif debug_mode and stderr and stderr ~= '' then
                naughty.notification({
                    app_name = 'Start-up Applications',
                    title = '<b>Oof! Error checking ' .. cmd .. '!</b>',
                    message = stderr:gsub('%\n', ''),
                    icon = require('beautiful').awesome_icon
                })
            end
        end
    )
end

awesome.connect_signal(
    'module::spawn_apps',
    function()
        if auto_start_disabled then return end

        -- Need the following when we come back from sleep
        -- run_once('systemctl reload-or-restart --now geoclue.service')
        -- run_once('killall darkman; ' ..
        -- 'XDG_DATA_DIRS=~/.config/darkman ' ..
        -- 'darkman run > ~/.cache/awesome/darkman.log 2>&1 &')
        -- No need for this since they are now part of start-up apps
        -- Just a fail safe mechanism in case user services fails
        run_once(apps.utils.ensure_darkman)

        run_once('systemctl --user start goimapnotify.service')
    end
)

if not auto_start_disabled then
    for _, app in ipairs(apps.run_on_start_up) do
        run_once(app)
    end
end

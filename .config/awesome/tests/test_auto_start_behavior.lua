-- Test-only override of the read-only os.getenv function.
-- luacheck: ignore 122
local home = assert(os.getenv('HOME'))
local utilities = home .. '/.config/awesome/utilities/'
local commands = {}
local checks = {}
local signals = {}
local original_getenv = os.getenv
os.getenv = function(name)
    if name == 'AWESOME_SKIP_AUTOSTART' then return nil end
    return original_getenv(name)
end

package.loaded.awful = { spawn = {
    with_shell = function(command) commands[#commands + 1] = command end,
    easy_async = function(argv, callback)
        checks[#checks + 1] = argv
        callback('', '', '', argv[#argv] == 'picom' and 0 or 1)
    end,
} }
package.loaded.naughty = { notification = function() error('unexpected notification') end }
package.loaded['configuration.config'] = { module = { auto_start = { debug_mode = false } } }
package.loaded['configuration.apps'] = { utils = { ensure_darkman = utilities .. 'ensure-darkman' }, run_on_start_up = {
    'setup-monitors',
    'picom -b --config ' .. home .. '/.config/awesome/configuration/picom.conf',
    'nm-applet',
    utilities .. 'suspend-hook.py &',
    utilities .. 'volctl',
    'systemctl --user start darkman.service',
} }
awesome = { connect_signal = function(name, callback) signals[name] = callback end }

dofile(home .. '/.config/awesome/module/auto-start.lua')
assert(#checks == 3, 'one-shot commands were mistaken for persistent processes')
assert(checks[1][2] == '-x' and checks[1][5] == 'picom', 'picom was not checked by exact name')
assert(checks[3][2] == '-f' and checks[3][5] == utilities .. 'suspend-hook.py',
    'resume watcher was not checked by its script path')
assert(table.concat(commands, ','):find('setup-monitors', 1, true))
assert(not table.concat(commands, ','):find('picom -b', 1, true), 'existing picom was relaunched')
assert(table.concat(commands, ','):find('systemctl --user start darkman.service', 1, true))

local before = #commands
signals['module::spawn_apps']()
assert(#commands == before + 2, 'resume did not check Darkman and goimapnotify')
assert(commands[before + 1] == utilities .. 'ensure-darkman',
    'resume did not use the conditional Darkman health check')

os.getenv = original_getenv
print('auto-start behavior tests passed')

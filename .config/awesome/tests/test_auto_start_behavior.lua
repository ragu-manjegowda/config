-- Test-only override of the read-only os.getenv function.
-- luacheck: ignore 122
local home = assert(os.getenv('HOME'))
local utilities = home .. '/.config/awesome/utilities/'
local commands = {}
local checks = {}
local signals = {}
local original_getenv = os.getenv
local test_user
os.getenv = function(name)
    if name == 'AWESOME_SKIP_AUTOSTART' then return nil end
    if name == 'USER' then return test_user end
    if name == 'LOGNAME' then return nil end
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
assert(#checks[1] == 3 and checks[1][2] == '-x' and checks[1][3] == 'picom',
    'picom was not checked by exact name without USER')
assert(#checks[3] == 3 and checks[3][2] == '-f' and checks[3][3] == utilities .. 'suspend-hook.py',
    'resume watcher was not checked by its script path')
assert(table.concat(commands, ','):find('setup-monitors', 1, true))
assert(not table.concat(commands, ','):find('picom -b', 1, true), 'existing picom was relaunched')
assert(table.concat(commands, ','):find('systemctl --user start darkman.service', 1, true))

local before = #commands
signals['module::spawn_apps']()
assert(#commands == before + 2, 'resume did not check Darkman and goimapnotify')
assert(commands[before + 1] == utilities .. 'ensure-darkman',
    'resume did not use the conditional Darkman health check')

test_user = 'desktop-user'
local prior_checks = #checks
dofile(home .. '/.config/awesome/module/auto-start.lua')
local scoped_check = checks[prior_checks + 1]
assert(#scoped_check == 5 and scoped_check[3] == '-u' and
    scoped_check[4] == test_user and scoped_check[5] == 'picom',
    'process check lost user scoping when USER is available')

os.getenv = original_getenv
print('auto-start behavior tests passed')

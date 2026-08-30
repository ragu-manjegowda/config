local home = assert(os.getenv('HOME'))
package.path = home .. '/.config/awesome/?.lua;' ..
    home .. '/.config/awesome/?/init.lua;' .. package.path

local fingerprint = require('module.lockscreen-fingerprint')
local callbacks = {}
local killed = {}
local matches, failures, retries = 0, 0, 0
local locked = true
local next_pid = 40

local controller = fingerprint.new {
    user = 'ragu',
    is_locked = function() return locked end,
    spawn = function(argv, handlers)
        assert(argv[1] == 'fprintd-verify' and argv[2] == '-f' and
            argv[3] == 'any' and argv[4] == 'ragu')
        next_pid = next_pid + 1
        callbacks[next_pid] = handlers
        return next_pid
    end,
    kill = function(pid) killed[#killed + 1] = pid end,
    retry = function(callback)
        retries = retries + 1
        callback()
    end,
    on_match = function() matches = matches + 1 end,
    on_no_match = function() failures = failures + 1 end
}

controller:start()
local first_pid = assert(controller.pid)
callbacks[first_pid].stdout('Verify result: verify-no-match (done)')
assert(failures == 1 and matches == 0, 'no-match must report a fingerprint failure')

callbacks[first_pid].stdout('Verify result: verify-match (done)')
assert(matches == 1 and controller.pid == nil and killed[1] == first_pid,
    'match must stop verification and authenticate once')
callbacks[first_pid].stdout('Verify result: verify-no-match (done)')
assert(failures == 1, 'stale output after success must be ignored')

controller:start()
local second_pid = assert(controller.pid)
callbacks[second_pid].exit('exit', 1)
assert(retries == 1 and controller.pid ~= nil and controller.pid ~= second_pid,
    'unexpected exit must restart while locked and active')

local third_pid = controller.pid
controller:stop()
callbacks[third_pid].stdout('Verify result: verify-match (done)')
assert(matches == 1 and killed[#killed] == third_pid,
    'stopped verifier must reject stale matches')

locked = false
controller:start()
assert(controller.pid == nil, 'fingerprint verification must not start while unlocked')

print('Lockscreen fingerprint tests passed')

local home = assert(os.getenv('HOME'))
local refresh = dofile(home .. '/.config/awesome/library/email-refresh.lua')
local mails_path = home .. '/.config/awesome/widget/email/mails.txt'
local notify_script = home .. '/.config/imapnotify/notify.sh'
local calls = {}
local now = 1000
local poll = refresh.new {
    mails_path = mails_path,
    notify_script = notify_script,
    clock = function() return now end,
    spawn = function(argv, callback)
        calls[#calls + 1] = { argv = argv, callback = callback }
    end,
}

poll()
poll()
assert(#calls == 1, 'overlapping refreshes started duplicate checks')
assert(calls[1].argv[1] == '/usr/bin/stat' and calls[1].argv[4] == mails_path)
calls[1].callback('980\n', '', '', 0)
assert(#calls == 1, 'recent mail summary started a needless sync')

now = 1100
poll()
calls[2].callback('900\n', '', '', 0)
assert(#calls == 3, 'stale mail summary did not start a sync')
assert(calls[3].argv[1] == '/usr/bin/timeout' and calls[3].argv[4] == '/bin/bash' and
    calls[3].argv[5] == notify_script, 'sync is not bounded or uses a shell command line')
poll()
assert(#calls == 3, 'sync in flight allowed another refresh')

-- A concurrently running goimapnotify sync makes notify.sh return promptly
-- without work; the following timer should still be allowed to try again.
calls[3].callback('', '', '', 0)
poll()
assert(#calls == 4, 'completed sync permanently disabled the fallback')
calls[4].callback('', 'missing', '', 1)
assert(#calls == 5, 'missing mail summary did not trigger recovery')
calls[5].callback('', '', '', 124)
poll()
assert(#calls == 6, 'timed-out sync permanently disabled the fallback')

print('email refresh tests passed')

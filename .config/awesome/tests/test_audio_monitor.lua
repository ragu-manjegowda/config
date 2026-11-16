-- Exercise the real pactl event parser without starting or killing processes.
local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
local events, timers, callbacks, killed, exit_handler = {}, {}, nil, nil, nil
local starts, spawn_error = 0, nil
package.loaded.gears = {
    object = function()
        return { emit_signal = function(_, name, ...)
            events[#events + 1] = { name, ... }
        end }
    end,
    timer = function(spec)
        function spec:again() self.started = true end
        function spec:stop() self.started = false end
        timers[#timers + 1] = spec
        return spec
    end,
}
package.loaded.awful = {
    spawn = setmetatable({
        with_line_callback = function(argv, handlers)
            assert(argv[1] == 'pactl' and argv[2] == 'subscribe')
            starts = starts + 1
            callbacks = handlers
            return spawn_error or (1233 + starts)
        end,
    }, { __call = function(_, argv) killed = argv end }),
}
awesome = { connect_signal = function(name, handler)
    assert(name == 'exit')
    exit_handler = handler
end }
dofile(root .. 'library/audio-monitor.lua')
assert(not callbacks)
timers[1].callback()
timers[1].callback()
assert(starts == 1, 'An active subscriber must not be duplicated')
callbacks.stdout("Event 'new' on source #283")
assert(events[1][1] == 'source' and events[1][2] == 'new' and events[1][3] == 283)
callbacks.stdout("Event 'change' on source #283")
assert(events[2][2] == 'change')
callbacks.stdout("Event 'remove' on source #283")
assert(events[3][2] == 'remove')
callbacks.stdout("Event 'new' on sink #282")
assert(events[4][1] == 'sink')
callbacks.stdout("Event 'change' on card #7")
assert(events[5][1] == 'source' and events[5][2] == nil and events[6][1] == 'sink')
local stale = callbacks
callbacks.exit('exit', 1)
assert(timers[1].started and timers[1].timeout == 2)
timers[1].callback()
assert(starts == 2)
stale.exit('exit', 1)
local before = #events
stale.stdout("Event 'new' on sink #999")
assert(#events == before, 'A retired subscriber must not emit events')
callbacks.exit('exit', 1)
assert(timers[1].timeout == 4, 'Repeated failures must back off')
spawn_error = 'pactl unavailable'
for attempt = 1, 6 do timers[1].callback() end
assert(timers[1].timeout == 30, 'Retry delay must be capped')
spawn_error = nil
timers[1].callback()
callbacks.stdout("Event 'change' on sink #282")
callbacks.exit('exit', 1)
assert(timers[1].timeout == 2, 'Healthy traffic must reset retry backoff')
timers[1].callback()
local last_pid = 1233 + starts
exit_handler()
assert(not timers[1].started and killed[1] == 'kill' and killed[3] == tostring(last_pid))
before = starts
callbacks.exit('signal', 15)
timers[1].callback()
assert(starts == before and not timers[1].started, 'Shutdown must not restart the subscriber')
print('audio event metadata, bounded reconnect and owned-process cleanup tests passed')

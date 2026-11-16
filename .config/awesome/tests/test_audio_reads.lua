local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local calls, completed = {}, {}
package.loaded.awful = { spawn = { easy_async = function(argv, callback)
    calls[#calls + 1] = { argv = argv, callback = callback }
end } }
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return root end },
    timer = setmetatable({ start_new = function() end }, {
        __call = function(_, spec) return spec end,
    }),
}
package.loaded['configuration.config'] = {
    display = { primary = { name = 'primary' } }, widget = { audio = {} },
}
package.loaded['library.display-brightness'] = { output = function() return 'primary' end }
package.loaded['library.audio-monitor'] = { connect_signal = function() end }
awesome = { connect_signal = function() end }
local audio = require('library.display-audio')
local function read(output, kind)
    audio.read(output, kind, function(state) completed[#completed + 1] = state.volume or -1 end)
end
read('primary', 'sink')
for index = 1, 30 do read('primary', 'sink') end
assert(#calls == 1, 'A burst must not start concurrent reads of the same endpoint')
calls[1].callback('{"available":true,"volume":10}', '', 'exit', 0)
assert(#calls == 2 and #completed == 1 and completed[1] == 10,
    'Events during an active read require one fresh follow-up read')
calls[2].callback('{"available":true,"volume":20}', '', 'exit', 0)
assert(#completed == 31 and #calls == 2)
for index = 2, #completed do assert(completed[index] == 20, 'Pending readers received stale state') end
read('primary', 'sink')
read('external', 'sink')
read('primary', 'source')
assert(#calls == 5, 'Independent outputs and device kinds must not block one another')
read('primary', 'sink')
calls[3].callback('', '', 'exit', 1)
assert(completed[#completed] == -1 and #calls == 6, 'A failed read must release pending work')
calls[6].callback('{"available":true,"volume":30}', '', 'exit', 0)
assert(completed[#completed] == 30)
local reentered = false
audio.read('primary', 'sink', function()
    reentered = true
    read('primary', 'sink')
end)
read('primary', 'sink')
calls[7].callback('{"available":true,"volume":40}', '', 'exit', 0)
assert(reentered and #calls == 8, 'Reentrant callbacks must share the follow-up read')
calls[8].callback('{"available":true,"volume":50}', '', 'exit', 0)
assert(#calls == 9)
calls[9].callback('{"available":true,"volume":60}', '', 'exit', 0)
assert(completed[#completed] == 60)
print('audio read coalescing, freshness, failure and reentrancy tests passed')

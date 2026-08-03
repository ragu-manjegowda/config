local awful = require('awful')
local gears = require('gears')

local monitor = gears.object {}
local subscriber_pid

local function start_subscriber()
    subscriber_pid = awful.spawn.with_line_callback({ 'pactl', 'subscribe' }, {
        stdout = function(line)
            if line:match("Event 'change' on source") then
                monitor:emit_signal('source')
            elseif line:match("Event 'change' on sink") then
                monitor:emit_signal('sink')
            end
        end,
    })
end

gears.timer {
    timeout = 2,
    autostart = true,
    single_shot = true,
    callback = function()
        awful.spawn.easy_async({
            'pkill',
            '--uid', os.getenv('USER'),
            '--full', '^pactl subscribe$',
        }, start_subscriber)
    end,
}

awesome.connect_signal('exit', function()
    if subscriber_pid then
        awful.spawn({ 'kill', '-TERM', tostring(subscriber_pid) }, false)
        subscriber_pid = nil
    end
end)

return monitor

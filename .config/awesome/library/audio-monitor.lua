local awful = require('awful')
local gears = require('gears')

local monitor = gears.object {}
local subscriber_pid
local subscriber_generation = 0
local stopping = false
local retry_delay = 2
local retry_timer

local function retry()
    if stopping then return end
    retry_timer.timeout = retry_delay
    retry_delay = math.min(30, retry_delay * 2)
    retry_timer:again()
end

local function start_subscriber()
    if stopping or subscriber_pid then return end
    subscriber_generation = subscriber_generation + 1
    local generation = subscriber_generation
    subscriber_pid = awful.spawn.with_line_callback({ 'pactl', 'subscribe' }, {
        stdout = function(line)
            if stopping or generation ~= subscriber_generation then return end
            retry_delay = 2
            local action, index = line:match("Event '(%w+)' on source #(%d+)")
            if action then
                monitor:emit_signal('source', action, tonumber(index))
            elseif line:match(" on sink #") then
                monitor:emit_signal('sink')
            elseif line:match(" on card #") or line:match(" on server ") then
                monitor:emit_signal('source')
                monitor:emit_signal('sink')
            end
        end,
        exit = function()
            if stopping or generation ~= subscriber_generation then return end
            subscriber_pid = nil
            retry()
        end,
    })
    if type(subscriber_pid) ~= 'number' then
        subscriber_pid = nil
        retry()
    end
end

retry_timer = gears.timer {
    timeout = 2,
    autostart = true,
    callback = function()
        retry_timer:stop()
        start_subscriber()
    end,
}

awesome.connect_signal('exit', function()
    stopping = true
    retry_timer:stop()
    if subscriber_pid then
        awful.spawn({ 'kill', '-TERM', tostring(subscriber_pid) }, false)
        subscriber_pid = nil
    end
end)

return monitor

#!/usr/bin/env lua

local root = os.getenv('HOME') .. '/.config/awesome/'
local calls, logs = {}, {}
local spawn_error
package.loaded.awful = {
    spawn = setmetatable({
        easy_async = function(command, callback)
            calls[#calls + 1] = { command = command, callback = callback }
            return spawn_error or 123
        end,
    }, { __call = function(_, command)
        logs[#logs + 1] = command
    end }),
}
local sound = dofile(root .. 'library/notification-sound.lua')
local notification = { app_name = 'test-app', id = 42, title = "test\ntitle; $(false)" }
assert(sound.play('message', notification))
assert(not sound.play('message', notification), 'notification burst spawned overlapping players')
assert(#calls == 1)
local command = calls[1].command
assert(command[1] == '/usr/bin/timeout' and command[2] == '--kill-after=1' and command[3] == '5')
assert(command[4] == '/usr/bin/env' and command[5] == 'CANBERRA_DRIVER=pulse')
assert(command[6] == 'canberra-gtk-play' and command[8] == 'message')
assert(command[9] == '--property=media.role=event')
assert(command[11]:find('app=test-app id=42 title=test title; $(false)', 1, true),
    'source metadata was lost or shell-interpreted')
calls[1].callback('', '', 'exit', 0)
assert(#logs == 0, 'successful sound logged an error')
assert(sound.play('message', notification), 'successful completion did not release player')
calls[2].callback('', 'backend stuck\n', 'exit', 124)
assert(#logs == 1 and logs[1][3] == 'awesome-notification-sound')
assert(logs[1][5]:find('app=test-app id=42', 1, true))
assert(logs[1][5]:find('code=124 error=backend stuck ', 1, true))
assert(sound.play('camera-shutter'), 'timeout did not release player')
calls[3].callback('', '', 'signal', 9)
assert(#logs == 2 and logs[2][5]:find('reason=signal code=9', 1, true))
spawn_error = 'cannot launch player'
assert(not sound.play('message'))
assert(#logs == 3 and logs[3][5]:find('cannot launch player', 1, true))
spawn_error = nil
assert(sound.play('message'), 'spawn failure permanently blocked subsequent sounds')
calls[5].callback('', '', 'exit', 0)

print('Notification sound lifecycle tests passed')

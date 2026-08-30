local awful = require('awful')
local naughty = require('naughty')

local notification = {}

function notification.finished(filename)
    local open_video = naughty.action { name = 'Open', icon_only = false }
    local delete_video = naughty.action { name = 'Delete', icon_only = false }
    open_video:connect_signal('invoked', function()
        awful.spawn({ 'xdg-open', filename }, false)
    end)
    delete_video:connect_signal('invoked', function()
        awful.spawn({ 'gio', 'trash', filename }, false)
    end)
    naughty.notification({
        app_name = 'Screen Recorder',
        timeout = 60,
        title = '<b>Recording Finished</b>',
        message = 'Recording can now be viewed.',
        actions = { open_video, delete_video }
    })
end

return notification

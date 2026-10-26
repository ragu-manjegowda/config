local awful = require('awful')

local sound = {}
local playing = false

local function label(value)
    return tostring(value or ''):gsub('[%c]', ' '):sub(1, 160)
end

function sound.play(event, notification)
    -- Coalesce bursts rather than accumulating sound processes after resume.
    if playing then
        return false
    end
    notification = notification or {}
    local context = string.format('event=%s app=%s id=%s title=%s',
        label(event), label(notification.app_name), label(notification.id),
        label(notification.title))
    local function log_failure(reason, code, stderr)
        awful.spawn({ '/usr/bin/logger', '-t', 'awesome-notification-sound',
            '--', string.format('%s reason=%s code=%s error=%s',
                context, label(reason), label(code), label(stderr)) }, false)
    end
    playing = true
    -- Select PulseAudio explicitly: ALSA fallback hid the sender and left an
    -- uncorked PipeWire ALSA stream behind when playback hung after resume.
    local pid = awful.spawn.easy_async({
        '/usr/bin/timeout', '--kill-after=1', '5',
        '/usr/bin/env', 'CANBERRA_DRIVER=pulse',
        'canberra-gtk-play', '-i', event,
        '--property=media.role=event',
        '--property=application.name=Awesome notification sound',
        '--description=' .. context,
    }, function(_, stderr, reason, code)
        playing = false
        if reason ~= 'exit' or code ~= 0 then
            log_failure(reason, code, stderr)
        end
    end)
    if type(pid) ~= 'number' then
        playing = false
        log_failure('spawn', '', pid)
    end
    return type(pid) == 'number'
end

return sound

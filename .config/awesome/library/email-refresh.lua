local M = {}

-- The mail sync script owns an exclusive flock, so it safely declines a
-- refresh when another sync is already running. Do not probe processes by
-- matching a shell command line: that probe matches its own parent shell.
function M.new(options)
    local in_progress = false
    local clock = options.clock or os.time
    local min_age = options.min_age or 60

    return function()
        if in_progress then return end
        in_progress = true

        options.spawn({ '/usr/bin/stat', '-c', '%Y', options.mails_path }, function(stdout, _, _, exit_code)
            local mtime = (exit_code == 0 and tonumber(stdout)) or 0
            if clock() - mtime < min_age then
                in_progress = false
                return
            end

            options.spawn({ '/usr/bin/timeout', '--kill-after=5', '240',
                '/bin/bash', options.notify_script }, function()
                in_progress = false
            end)
        end)
    end
end

return M

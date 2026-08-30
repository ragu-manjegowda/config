local fingerprint = {}

function fingerprint.new(options)
    local controller = {
        active = false,
        generation = 0,
        pid = nil
    }

    local function start_process()
        if controller.pid or not controller.active or not options.is_locked() then return end

        controller.generation = controller.generation + 1
        local generation = controller.generation
        local pid
        pid = options.spawn({ 'fprintd-verify', '-f', 'any', options.user }, {
            stdout = function(line)
                if generation ~= controller.generation or not controller.active or
                    not options.is_locked() then
                    return
                end
                if line:find('verify-no-match', 1, true) then
                    options.on_no_match()
                elseif line:find('verify-match', 1, true) then
                    controller:stop()
                    options.on_match()
                end
            end,
            exit = function()
                if generation ~= controller.generation then return end
                if controller.pid == pid then controller.pid = nil end
                if controller.active and options.is_locked() then
                    options.retry(function()
                        if generation == controller.generation then start_process() end
                    end)
                end
            end
        })
        controller.pid = pid
    end

    function controller:start()
        controller.active = true
        start_process()
    end

    function controller:stop()
        controller.active = false
        controller.generation = controller.generation + 1
        local pid = controller.pid
        controller.pid = nil
        if pid then options.kill(pid) end
    end

    return controller
end

return fingerprint

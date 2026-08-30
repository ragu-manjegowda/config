local recorder_state = require('widget.screen-recorder.screen-recorder-state')

local recorder_source = {}

local function display_for_output(output_name, fallback)
    for s in screen do
        if s.valid and s.outputs and s.outputs[output_name] then
            return {
                mode = s.geometry.width .. 'x' .. s.geometry.height,
                position = s.geometry.x .. 'x' .. s.geometry.y
            }, true
        end
    end
    return fallback, false
end

function recorder_source.new(config)
    local path = recorder_state.path()
    local state = recorder_state.load(
        path,
        config.widget.screen_recorder.display_target or 'primary',
        config.widget.screen_recorder.audio or false)
    local controller = { state = state }

    function controller:external_connected()
        local _, connected = display_for_output(
            config.display.external.name, config.display.external)
        return connected
    end

    function controller:available(source)
        return source ~= 'external' and source ~= 'both' or self:external_connected()
    end

    function controller:resolve()
        local primary, primary_connected = display_for_output(
            config.display.primary.name, config.display.primary)
        local external, external_connected = display_for_output(
            config.display.external.name, config.display.external)
        if (self.state.source == 'primary' or self.state.source == 'both') and
            not primary_connected then
            return nil, 'Primary display unavailable'
        end
        local root_width, root_height = root.size()
        return recorder_state.resolve(
            self.state, primary, external, external_connected, root_width, root_height)
    end

    function controller:save()
        return pcall(recorder_state.save, path, self.state)
    end

    return controller
end

return recorder_source

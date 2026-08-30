local awful = require('awful')
local gears = require('gears')

local settings = {}

function settings.new(options)
    local controller = {}
    local state = options.source_controller.state
    local labels = {
        primary = 'Primary',
        external = 'External',
        both = 'Both',
        region = 'Select area'
    }

    local function save()
        local success, err = options.source_controller:save()
        if not success then options.on_error('Settings were not saved', tostring(err)) end
    end

    function controller:set_source(source)
        if not options.can_update() then return end
        if not options.source_controller:available(source) then
            self:refresh('External display unavailable')
            return
        end
        state.source = source
        save()
        self:refresh()
    end

    function controller:refresh(message)
        for source, button in pairs(options.buttons) do
            local available = options.source_controller:available(source)
            local selected = state.source == source
            button.available, button.selected = available, selected
            button.opacity = available and 1 or 0.55
            button.shape_border_width = selected and options.dpi(2) or options.dpi(0)
            button.shape_border_color = selected and options.accent or options.transparent
            local label = button:get_children_by_id(source .. '_source_label')[1]
            local label_text = labels[source]
            if source == 'region' and state.region then label_text = 'Saved area' end
            if selected then
                label_text = source == 'region' and 'Area [x]' or (label_text .. ' [x]')
            elseif not available then
                label_text = label_text .. ' off'
            end
            label:set_text(label_text)
        end

        if message then
            options.area:set_text(message)
            options.source_hint:set_text('1 Primary · 2 External · 3 Both · 4 Area')
            options.cancel_hint:set_text('Esc/right-click cancel; saved area stays')
            return
        end
        local geometry, err = options.source_controller:resolve()
        options.area:set_text(geometry and options.summary(geometry) or err)
        options.source_hint:set_text('1 Primary · 2 External · 3 Both · 4 Area')
        if state.source == 'region' then
            options.cancel_hint:set_text('Esc returns · click Area to redraw')
        elseif state.region then
            options.cancel_hint:set_text('Esc returns · Area reuses saved region')
        else
            options.cancel_hint:set_text('Esc returns to recorder')
        end
    end

    local keygrabber = awful.keygrabber {
        auto_start = false,
        keypressed_callback = function(_, _, key)
            if key == 'Escape' then
                options.on_escape()
            elseif key == '1' then
                controller:set_source('primary')
            elseif key == '2' then
                controller:set_source('external')
            elseif key == '3' then
                controller:set_source('both')
            elseif key == '4' then
                if state.source == 'region' or not state.region then
                    options.on_select_area()
                else
                    controller:set_source('region')
                end
            end
        end
    }

    function controller:start()
        keygrabber:start()
    end

    function controller:stop()
        keygrabber:stop()
    end

    for source, button in pairs(options.buttons) do
        local selected_source = source
        button:buttons(gears.table.join(awful.button({}, 1, nil, function()
            if selected_source == 'region' then
                if state.source == 'region' or not state.region then
                    options.on_select_area()
                else
                    controller:set_source('region')
                end
            else
                controller:set_source(selected_source)
            end
        end)))
    end

    return controller
end

return settings

local home = assert(os.getenv("HOME"))
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" .. package.path

local keygrabber
package.loaded.awful = {
    button = function(_, _, _, callback)
        return { callback = callback }
    end,
    keygrabber = function(args)
        keygrabber = args
        function args:start() self.started = true end
        function args:stop() self.started = false end
        return args
    end
}
package.loaded.gears = {
    table = { join = function(button) return { button } end }
}

local function fake_button(source)
    local label = { text = '' }
    function label:set_text(value) self.text = value end
    local button = {}
    function button:get_children_by_id(id)
        if id == source .. '_source_label' then return { label } end
        return {}
    end
    function button:buttons(value) self.binding = value[1] end
    button.label = label
    return button
end

local buttons = {
    primary = fake_button('primary'),
    external = fake_button('external'),
    both = fake_button('both'),
    region = fake_button('region')
}
local source_controller = {
    state = { source = 'region', region = { x = 10, y = 20, width = 800, height = 600 } }
}
function source_controller:available(source)
    return source ~= 'external' and source ~= 'both'
end
function source_controller:resolve()
    return self.state.region
end
function source_controller:save()
    self.saved = true
    return true
end

local area = { text = '' }
function area:set_text(value) self.text = value end
local source_hint = { text = '' }
function source_hint:set_text(value) self.text = value end
local cancel_hint = { text = '' }
function cancel_hint:set_text(value) self.text = value end
local escaped = false
local area_requested = false

local settings = require("widget.screen-recorder.screen-recorder-settings").new {
    source_controller = source_controller,
    buttons = buttons,
    area = area,
    source_hint = source_hint,
    cancel_hint = cancel_hint,
    dpi = function(value) return value end,
    accent = 'accent',
    transparent = 'transparent',
    summary = function() return '800x600 at 10,20' end,
    can_update = function() return true end,
    on_select_area = function() area_requested = true end,
    on_escape = function() escaped = true end,
    on_error = function() error('unexpected settings error') end
}

settings:refresh()
assert(buttons.region.label.text == 'Area [x]',
    "selected source must have a non-color marker")
assert(buttons.external.label.text == 'External off' and buttons.external.opacity == 0.55,
    "unavailable source must remain readable and explicit")
assert(area.text == '800x600 at 10,20', "settings must show resolved geometry")
assert(source_hint.text:match('1 Primary') and source_hint.text:match('4 Area'),
    "settings must explain every numeric source shortcut")
assert(cancel_hint.text:match('Esc'), "settings must advertise Escape behavior")

keygrabber.keypressed_callback(nil, nil, '1')
assert(source_controller.state.source == 'primary' and source_controller.saved,
    "keyboard source selection must persist")
area_requested = false
keygrabber.keypressed_callback(nil, nil, '4')
assert(source_controller.state.source == 'region' and not area_requested,
    "keyboard area selection must reuse a saved region")
keygrabber.keypressed_callback(nil, nil, '4')
assert(area_requested, "selecting an active area again must invoke the selector")
keygrabber.keypressed_callback(nil, nil, 'Escape')
assert(escaped, "Escape must leave recorder settings")

print("Screen recorder settings tests passed")

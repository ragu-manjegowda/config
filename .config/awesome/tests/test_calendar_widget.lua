-- Load the real calendar UI with no X11, mail, OAuth, filesystem cache or network.
local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local navigation = require('library.calendar-navigation')
local month_type = {}
local months = {}
local make
make = function(args)
    if args and args.mock_widget then return args end
    local value = args or {}
    value.mock_widget, value.children, value.handlers = true, {}, {}
    local indices = {}
    for index in pairs(args or {}) do if type(index) == 'number' then indices[#indices + 1] = index end end
    table.sort(indices)
    for _, index in ipairs(indices) do value.children[#value.children + 1] = make(args[index]) end
    function value:get_children() return self.children end

    function value:set_widget(child) self.children = { child } end

    function value:add(child) self.children[#self.children + 1] = child end

    function value:buttons(buttons) self.clicks = buttons end

    function value:connect_signal(name, callback) self.handlers[name] = callback end

    function value:emit_signal(name) if self.handlers[name] then self.handlers[name]() end end

    function value:get_text() return self.text end

    function value:set_markup(text) self.markup = text end

    if value.widget == month_type then
        months[#months + 1] = value
        function value:get_date() return self.date end

        function value:set_date(date)
            self.date, self.children = date, {}
            if not date then return end
            self.children[1] = self.fn_embed(make { text = 'Month header' }, 'header', date)
            for day = 1, navigation.days_in_month(date.year, date.month) do
                self.children[#self.children + 1] = self.fn_embed(make { text = tostring(day) },
                    day == date.day and 'focus' or 'normal',
                    { year = date.year, month = date.month, day = day })
            end
        end

        value:set_date(value.date)
    end
    return value
end
local widgets = setmetatable({
    textbox = function(text) return make { text = text } end,
    calendar = { month = month_type },
    imagebox = {},
}, { __call = function(_, args) return make(args) end })
package.loaded.wibox = {
    widget = widgets,
    container = { margin = {}, background = {}, place = {} },
    layout = { fixed = { horizontal = {}, vertical = {} }, align = { horizontal = {} }, grid = {} },
}
local wibox_signals, client_signals, keygrabber_signals, timers, root_buttons = {}, {}, {}, {}, {}
package.loaded.wibox.connect_signal = function(name, callback) wibox_signals[name] = callback end
client = { connect_signal = function(name, callback) client_signals[name] = callback end }
local owner = { visible = true, cursor = 'left_ptr', handlers = {} }
function owner:connect_signal(name, callback) self.handlers[name] = callback end

function owner:disconnect_signal(name) self.handlers[name] = nil end

mouse = { current_wibox = owner }
package.loaded['widget.clickable-container'] = {}
package.loaded.beautiful = {
    transparent = 'transparent',
    background = 'background',
    groups_bg = 'groups',
    fg_normal = 'icons',
    fg_focus = 'focus-text',
    bg_focus = 'focus',
    accent = 'accent',
    system_cyan_light = 'us-marker',
    system_magenta_light = 'work-marker',
    system_red_light = 'input-error',
    xresources = { apply_dpi = function(value) return value end },
    font_regular = function() return 'regular' end,
    font_bold = function() return 'bold' end,
}
package.loaded.gears = {
    timer = function(args)
        function args:start() self.started = true end

        function args:stop() self.started = false end

        function args:again() self.started = true end

        timers[#timers + 1] = args
        return args
    end,
    filesystem = { get_configuration_dir = function() return root end },
    shape = { rounded_rect = function() end, circle = {}, rounded_bar = {} },
    table = {
        join = function(...) return { ... } end,
        hasitem = function(items, target) for _, item in ipairs(items) do if item == target then return true end end end,
    },
}
package.loaded['configuration.config'] = { widget = { calendar_holidays = {} } }
local requests, tooltips, grabber = {}, {}, nil
local notifications = {}
package.loaded.naughty = { notification = function(args) notifications[#notifications + 1] = args end }
local keygrabber = {}
keygrabber.connect_signal = function(name, callback) keygrabber_signals[name] = callback end
setmetatable(keygrabber, {
    __call = function(_, args)
        grabber = args
        function grabber:start()
            if self.grabber or keygrabber.current_instance then return false end
            self.grabber, self.active = function() end, true
            keygrabber.current_instance = self
            if keygrabber_signals['property::current_instance'] then
                keygrabber_signals['property::current_instance'](self)
            end
        end

        function grabber:stop()
            -- Real Awesome stops the CURRENT grab when an inactive object passes nil.
            local callback = self.grabber or (keygrabber.current_instance and keygrabber.current_instance.grabber)
            if callback and keygrabber.current_instance and keygrabber.current_instance.grabber == callback then
                keygrabber.current_instance = nil
            end
            self.grabber, self.active = nil, false
            self.stops = (self.stops or 0) + 1
            self.stop_callback()
            if keygrabber_signals['property::current_instance'] then
                keygrabber_signals['property::current_instance'](nil)
            end
        end

        return grabber
    end
})
package.loaded.awful = {
    button = function(args, _, _, callback)
        if args.button then return args end
        return callback
    end,
    mouse = {
        append_global_mousebindings = function(buttons)
            for _, binding in ipairs(buttons) do
                assert(type(binding) == 'table' and binding.button and binding.on_press,
                    'Root mouse bindings require modern awful.button objects, not flattened raw C buttons')
                root_buttons[#root_buttons + 1] = binding
            end
        end
    },
    util = { table = { join = function(...) return { ... } end } },
    spawn = { easy_async = function(argv, callback) requests[#requests + 1] = { argv = argv, callback = callback } end },
    tooltip = function(args)
        local tooltip = args
        tooltip.cells = {}
        function tooltip:add_to_object(cell) self.cells[cell] = true end

        function tooltip:remove_from_object(cell) self.cells[cell] = nil end

        function tooltip:set_text(text) self.text = text end

        tooltips[#tooltips + 1] = tooltip
        return tooltip
    end,
    keygrabber = keygrabber,
}
local signals = {}
awesome = { connect_signal = function(name, callback) signals[name] = callback end }
local original_date, original_open = os.date, io.open
os.date = function(format, timestamp) -- luacheck: ignore 122
    if format == '*t' and not timestamp then return { year = 2026, month = 10, day = 5 } end
    return original_date(format, timestamp)
end
io.open = function(path) -- luacheck: ignore 122
    assert(path:match('/awesome/calendar%-holidays%.json$'), 'Unexpected file read')
    return nil
end
local widget = require('widget.calendar')
widget:set_input_owner(owner)
local function contains(node, text)
    if node.text == text then return true end
    for _, child in ipairs(node:get_children()) do if contains(child, text) then return true end end
end
local function button(node, text)
    if node.clicks and contains(node, text) then return node end
    for _, child in ipairs(node:get_children()) do
        local found = button(child, text); if found then return found end
    end
end
local function by_id(node, id)
    if node.id == id then return node end
    for _, child in ipairs(node:get_children()) do
        local found = by_id(child, id); if found then return found end
    end
end
local function click(text)
    local target = assert(button(widget, text), 'No button: ' .. text)
    target.clicks[1]()
end
click('October')
assert(widget:get_navigation_state().mode == 'months')
click('May')
assert(widget:get_navigation_state().month == 5 and widget:get_navigation_state().mode == 'month')
click('2026')
assert(widget:get_navigation_state().mode == 'years')
click('2028')
assert(widget:get_navigation_state().year == 2028 and widget:get_navigation_state().mode == 'months')
click('Feb')
assert(widget:get_navigation_state().month == 2 and widget:get_navigation_state().mode == 'month')
click('Go to date')
assert(grabber.active)
local input = assert(by_id(widget, 'calendar_date_input'))
local prompt = assert(by_id(widget, 'calendar_date_prompt'))
local input_card = assert(by_id(widget, 'calendar_date_input_card'))
assert(input.text == '|YYYY-MM-DD' and input.opacity < 1, 'The empty entry caret must precede its format placeholder')
assert(input_card.bg == 'background' and input_card.fg == 'icons' and input_card.border_width == 0 and input_card.shape,
    'The non-clickable input must use the same theme colors as the former button')
assert(input_card.clicks and not button(widget, 'Cancel'),
    'The field must focus on click without a separate Cancel button')
assert(prompt.children[1] == input_card and prompt.visible, 'The entry must fill its visible prompt row')
local help = tooltips[2]
assert(help.objects[1] == input_card and help.text == 'format: `yyyy-mm-dd` or `yyyy-mm` or `yyyy`'
    .. '\n press: `enter` to apply or `escape` to cancel', 'Hover help must remain exactly two concise lines')
input_card:emit_signal('mouse::enter')
assert(owner.cursor == 'hand1', 'Date entry hover must show a hand cursor')
input_card:emit_signal('mouse::leave')
assert(owner.cursor == 'left_ptr')
assert(timers[1].started, 'Caret blinking must start only after input is acquired')
timers[1].callback()
assert(input.text == ' YYYY-MM-DD', 'Caret must blink off without changing the placeholder position')
timers[1].callback()
assert(input.text == '|YYYY-MM-DD')
input_card.clicks[1]()
assert(grabber.active and input.text == '|YYYY-MM-DD', 'Clicking a focused entry must retain input ownership')
for character in ('2040-02-30'):gmatch('.') do grabber.keypressed_callback(grabber, {}, character) end
grabber.keypressed_callback(grabber, {}, 'Return')
assert(grabber.active and keygrabber.current_instance == grabber,
    'Invalid dates must keep keyboard input available for correction')
assert(#notifications == 0 and contains(widget, 'Enter a valid YYYY-MM-DD, YYYY-MM or YYYY'),
    'Invalid input must use the inline message without creating a notification')
assert(input_card.border_color == 'input-error' and input_card.border_width == 1,
    'Invalid input must visibly highlight the entry border')
assert(widget:get_navigation_state().year == 2028 and widget:get_navigation_state().day == nil,
    'Invalid input must not modify the selected date')
grabber.keypressed_callback(grabber, { 'Control' }, 'u')
assert(input_card.border_width == 0, 'Editing must clear the invalid-entry border')
assert(input.text == '|YYYY-MM-DD', 'Clearing the entry must put the caret before its placeholder')
for character in ('2040-02-29'):gmatch('.') do grabber.keypressed_callback(grabber, {}, character) end
grabber.keypressed_callback(grabber, {}, 'Return')
local selected = widget:get_navigation_state()
assert(selected.year == 2040 and selected.month == 2 and selected.day == 29 and not grabber.active)
local function assert_same_date(before)
    local after = widget:get_navigation_state()
    assert(after.year == before.year and after.month == before.month and after.day == before.day
        and after.mode == before.mode, 'Cancelling must not change the selected date or view')
end
click('Go to date')
for character in ('2035-12'):gmatch('.') do grabber.keypressed_callback(grabber, {}, character) end
grabber.keypressed_callback(grabber, {}, 'Escape')
assert(not grabber.active and keygrabber.current_instance == nil)
assert_same_date(selected)
assert(not timers[1].started, 'Cancelling must stop the caret timer')

click('Go to date')
function owner:find_widgets(x, y)
    if x == 10 and y == 10 then return { { widget = input_card } } end
    return {}
end

wibox_signals['button::press'](owner, 10, 10)
assert(grabber.active, 'Clicks inside the date field must preserve input')
wibox_signals['button::press'](owner, 20, 20)
assert(not grabber.active and not timers[1].started,
    'Clicking elsewhere within Calendar Center must cancel the date prompt')
click('Go to date')
wibox_signals['button::press']({})
assert(not grabber.active and not timers[1].started, 'Clicking another widget must release calendar input')
click('Go to date')
client_signals.focus()
assert(not grabber.active and not timers[1].started, 'Focusing another client must release calendar input')
click('Go to date')
client_signals['button::press']()
assert(not grabber.active, 'Clicking another client must release calendar input')
click('Go to date')
root_buttons[1].on_press()
assert(not grabber.active and not timers[1].started, 'Clicking the desktop must release calendar input')
click('Go to date')
owner.visible = false
owner.handlers['property::visible']()
assert(not grabber.active and not timers[1].started, 'Hiding the owner must release its prompt')
owner.visible = true
click('Go to date')
local superseding = { grabber = function() end }
keygrabber.current_instance = superseding
keygrabber_signals['property::current_instance'](superseding)
assert(not timers[1].started and not prompt.visible and keygrabber.current_instance == superseding,
    'Another grab must stop the caret without being cancelled by calendar cleanup')
widget:stop_prompt()
assert(keygrabber.current_instance == superseding)
keygrabber.current_instance = nil
click('Go to date')
assert(grabber.active, 'A stale date transaction must recover on the next focus request')
widget:stop_prompt()
click('Go to date')
for _, key in ipairs({ 'KP_2', 'KP_0', 'KP_4', 'KP_0', 'KP_Subtract', 'KP_0', 'KP_2', 'KP_Subtract', 'KP_2', 'KP_9' }) do
    grabber.keypressed_callback(grabber, {}, key)
end
assert(input.text == '2040-02-29|', 'Numeric keypad entry must work like ordinary digit keys')
grabber.keypressed_callback(grabber, {}, 'KP_Enter')
assert(not grabber.active)
assert_same_date(selected)
click('Go to date')
grabber.keypressed_callback(grabber, {}, '9')
grabber.keypressed_callback(grabber, {}, 'Escape')
assert(not grabber.active and keygrabber.current_instance == nil)
assert_same_date(selected)
click('Go to date')
assert(grabber.active, 'The prompt must reopen normally after cancellation')
widget:stop_prompt()

-- A closed calendar still receives module::locked after the password grab starts.
local password = { grabber = function() end }
local stops = grabber.stops
keygrabber.current_instance = password
signals['module::locked']()
assert(keygrabber.current_instance == password and password.grabber and grabber.stops == stops,
    'An inactive calendar must not stop the lockscreen password grab')
widget:stop_prompt()
assert(keygrabber.current_instance == password and grabber.stops == stops,
    'Closing an inactive calendar must leave another keyboard grab untouched')
click('Go to date')
assert(keygrabber.current_instance == password and not grabber.active,
    'Calendar input must not start or show a stuck prompt while another grab owns input')
keygrabber.current_instance = nil

click('Go to date')
signals['module::locked']()
assert(not grabber.active, 'Locking must release only the calendar prompt')
click('Go to date')
widget:stop_prompt()
assert(not grabber.active, 'Closing the calendar must release its prompt')
click('Today')
assert(widget:get_navigation_state().day == 5)
widget:update()
widget:update()
assert(#requests == 1, 'Concurrent holiday refreshes must be coalesced')
assert(requests[1].argv[1] == '/usr/bin/timeout' and requests[1].argv[4] == '/usr/bin/python3')
requests[1].callback(
    [[{"ok":true,"window":{"start":"2025-01-01","end":"2028-01-01"},"events":[{"date":"2026-10-12","title":"US holiday","source":"us"},{"date":"2026-10-13","title":"Company holiday <test>","source":"work"}],"errors":[]}]],
    '', 'exit', 0)
local calendar = months[1]
local header = assert(by_id(calendar, 'calendar_month_year_header'))
assert(header.widget == package.loaded.wibox.container.place and header.halign == 'center',
    'The month and year must be centered as one heading above the date grid')
local us, work
for _, cell in ipairs(calendar:get_children()) do
    if cell.border_color == 'us-marker' then us = cell end
    if cell.border_color == 'work-marker' then work = cell end
end
assert(us and work, 'Both holiday sources need their own markers')
work:emit_signal('mouse::enter')
assert(tooltips[1].text == 'Work: Company holiday <test>', 'Tooltip must use plain text')
click('October')
assert(next(tooltips[1].cells) == nil, 'Changing views must retire old day tooltip bindings')
os.date, io.open = original_date, original_open -- luacheck: ignore 122
print('calendar month/year selectors, date prompt and holiday UI tests passed')

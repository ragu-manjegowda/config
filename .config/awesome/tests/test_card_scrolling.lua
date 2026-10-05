-- Real email/notification widgets, with fixture cards and no mail/X11 services.
local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local nodes, requests, signals, delayed = {}, {}, {}, {}
local node
node = function(spec)
    if spec and spec.handlers then return spec end
    local value = { children = {}, handlers = {}, visible = true }
    for key, item in pairs(spec or {}) do
        if type(key) == 'number' and type(item) == 'table' then
            item = node(item)
            value.children[#value.children + 1] = item
        end
        value[key] = item
    end
    function value:connect_signal(name, callback) self.handlers[name] = callback end

    function value:disconnect_signal(name) self.handlers[name] = nil end

    function value:emit_signal(name) if self.handlers[name] then self.handlers[name]() end end

    function value:buttons(bindings) self.bindings = bindings end

    function value:add(child)
        self.children[#self.children + 1] = child; self:emit_signal('widget::layout_changed')
    end

    function value:reset()
        self.children = {}; self:emit_signal('widget::layout_changed')
    end

    function value:get_children_by_id(id)
        local matches = {}
        local function visit(current)
            if current.id == id then matches[#matches + 1] = current end
            for _, child in ipairs(current.children) do visit(child) end
        end
        visit(self)
        return matches
    end

    nodes[#nodes + 1] = value
    return value
end
local function height(value)
    if value.visible == false then return 0 end
    if value.forced_height then return value.forced_height end
    if value.fixture_height then return value.fixture_height end
    if value.widget == 'textbox' then return 12 end
    local result, count = 0, 0
    for _, child in ipairs(value.children) do
        local h = height(child)
        if child.visible ~= false then
            count = count + 1
            result = value.layout == 'vertical' and result + h or math.max(result, h)
        end
    end
    if value.layout == 'vertical' then result = result + math.max(0, count - 1) * (value.spacing or 0) end
    result = result + 2 * (value.margins or 0) + (value.top or 0) + (value.bottom or 0)
    if value.widget == 'constraint' then result = math.min(result, value.height or result) end
    return result
end
local base = { fit_widget = function(_, _, child, width) return width, height(child) end }
package.loaded['wibox.widget.base'] = base
package.loaded.wibox = {
    widget = setmetatable({ base = base, textbox = 'textbox', imagebox = 'imagebox' }, {
        __call = function(_, spec) return node(spec) end,
    }),
    layout = { fixed = { vertical = 'vertical', horizontal = 'horizontal' }, align = {}, stack = 'stack' },
    container = { margin = 'margin', background = 'background', constraint = 'constraint' },
}
local timer = setmetatable({
    start_new = function() end,
    delayed_call = function(fn) delayed[#delayed + 1] = fn end,
}, { __call = function() return {} end })
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return root end },
    shape = {},
    string = { xml_escape = function(text) return text end },
    timer = timer,
    table = { join = function(...) return { ... } end },
}
package.loaded.awful = {
    spawn = { easy_async = function(_, callback) requests[#requests + 1] = callback end },
    button = function(_, button, press, release) return { button = button, callback = press or release } end,
}
package.loaded.beautiful = {
    xresources = { apply_dpi = function(value) return value end, get_dpi = function() return 96 end },
    font_regular = function() return '' end,
    font_bold = function() return '' end,
    background = '#111111',
    groups_bg = '#222222',
    fg_normal = '#ffffff',
    bg_focus = '#333333',
}
package.loaded.naughty = { notification = function() end }
package.loaded['library.email-refresh'] = { new = function() return function() end end }
awesome = { connect_signal = function(name, callback) signals[name] = callback end }
screen = { connect_signal = function() end }
local function flush()
    while #delayed > 0 do
        local callbacks = delayed; delayed = {}; for _, fn in ipairs(callbacks) do fn() end
    end
end
local function scroll_area(list)
    for _, value in ipairs(nodes) do
        if value.layout == 'stack' and value.bindings then
            local clip = value[1]
            if clip and clip.widget == 'constraint' and clip[1][1][1][1] == list then return value end
        end
    end
    error('Fixture could not locate the real list scrolling area')
end
local function scroll_margin(list)
    for _, value in ipairs(nodes) do if value.widget == 'margin' and value[1] == list then return value end end
    error('Missing scrolling margin')
end
local function wheel(area, direction)
    for _, binding in ipairs(area.bindings) do
        if binding.button == (direction == 'down' and 5 or 4) then
            binding.callback(); return
        end
    end
    error('Missing wheel binding')
end
local function check_cycle(report, list, viewport, expected)
    report:set_viewport_height(viewport)
    local area, margin = scroll_area(list), scroll_margin(list)
    assert(-margin.top == expected[1], 'First card must start at the top')
    local positions = {}; local y = 0
    for i, card in ipairs(list.children) do
        positions[i] = y; y = y + height(card) + (list.spacing or 0)
    end
    for i = 2, #expected do
        wheel(area, 'down')
        assert(math.abs(-margin.top - expected[i]) < 0.001, 'Downward wheel stopped between cards')
        local fits = false
        for index, card in ipairs(list.children) do
            local top = positions[index] + margin.top
            if top >= -0.001 and top + height(card) <= report:get_viewport_height() + 0.001 then fits = true end
        end
        assert(fits, 'No complete card is readable at the snapped position')
    end
    wheel(area, 'down'); assert(math.abs(-margin.top - expected[#expected]) < 0.001, 'Bottom overscroll')
    for i = #expected - 1, 1, -1 do
        wheel(area, 'up')
        assert(math.abs(-margin.top - expected[i]) < 0.001, 'Reverse scroll skipped a valid card alignment')
    end
    wheel(area, 'up'); assert(margin.top == 0, 'Top overscroll')
    return area, margin
end

local email = require('widget.email')
local email_list
for _, value in ipairs(nodes) do
    if value.layout == 'vertical' and value.spacing == 5 and value.children[1] and value.children[1].widget == 'background' then
        email_list = value; break
    end
end
assert(email_list)
local data = 'Unread Count: 4\n'
for i = 1, 4 do
    data = data ..
    'From: Example Sender ' .. i .. '\nSubject: Fixture message ' .. i .. '\nLocal Date: 2026-01-01 10:00:00\n'
end
signals['module::email:show'](); requests[#requests](data, '', 'exit', 0)
assert(#email_list.children == 4 and email:get_minimum_viewport_height() == 88)
check_cycle(email, email_list, 110, { 0, 82, 175, 257 })
check_cycle(email, email_list, 155, { 0, 59.5, 152.5, 212 })
email:set_viewport_context(760, { dpi = 96, screen = {} })
assert(scroll_margin(email_list).top == 0, 'Width change lost the first-card alignment')
signals['module::email:show'](); requests[#requests]('Unread Count: 0\n', '', 'exit', 0)
wheel(scroll_area(email_list), 'down')
assert(scroll_margin(email_list).top == 0, 'Empty mailbox must not have artificial scrolling padding')

local cards = { node { fixture_height = 80 }, node { fixture_height = 120 }, node { fixture_height = 90 } }
local notif_list = node { layout = 'vertical', spacing = 5, cards[1], cards[2], cards[3] }
local view = { notifbox_layout = notif_list, remove_notifbox_empty = false }
package.loaded['widget.notif-center.build-notifbox'] = {
    new_view = function() return view end, remove_view = function() end,
}
package.loaded['widget.notif-center.clear-all'] = function() return node() end
local s = { valid = true, geometry = { width = 3440, height = 1440 } }
local notifications = require('widget.notif-center')(s)
flush()
assert(notifications:get_minimum_viewport_height() == 120)
check_cycle(notifications, notif_list, 120, { 0, 85, 180 })
check_cycle(notifications, notif_list, 150, { 0, 70, 150 })
local area, margin = check_cycle(notifications, notif_list, 130, { 0, 80, 170 })
wheel(area, 'down'); wheel(area, 'down')
notifications:set_viewport_height(120)
assert(-margin.top == 180, 'Bottom must re-align after the viewport changes')
wheel(area, 'up'); assert(-margin.top == 85, 'Reverse step after bottom resize must center the previous card')
notif_list.children = { cards[1], cards[3] }; notif_list:emit_signal('widget::layout_changed'); flush()
wheel(area, 'up'); assert(margin.top == 0, 'Removing a card must not strand scrolling between rows')
notif_list.children = { node { fixture_height = 190 } }
notif_list:emit_signal('widget::layout_changed'); flush()
notifications:set_viewport_height(200)
assert(notifications:get_viewport_height() == 190,
    'One full notification may exceed the old default list cap when the panel has room')
wheel(area, 'down'); assert(margin.top == 0, 'A single complete card must not scroll into blank space')
print('email and notification full-card forward/reverse scrolling tests passed')

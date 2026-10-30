-- Real Pango fonts with synthetic widget data; no display, mail, OAuth or network.
-- luacheck: globals awesome
-- luacheck: ignore 212
local directory = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = directory .. '?.lua;' .. directory .. '?/init.lua;' .. package.path
local lgi = require('lgi')
local Pango = lgi.Pango
local resolution = 96
package.loaded.gears = { filesystem = { get_configuration_dir = function() return directory end } }
package.loaded.beautiful = { xresources = { get_dpi = function() return resolution end } }
local fonts = require('theme.default-theme').theme
local metrics = require('library.text-metrics')
for _, dpi in ipairs { 96, 120, 144, 192 } do
    resolution = dpi
    local nodes, requests, signals = {}, {}, {}
    local function node(spec)
        if spec and spec.children then return spec end
        local value = spec or {}
        value.children = {}
        for _, child in ipairs(spec or {}) do value.children[#value.children + 1] = node(child) end
        function value:add(child) self.children[#self.children + 1] = child end
        function value:remove(index) table.remove(self.children, index) end
        function value:reset() self.children = {} end
        function value:buttons() end
        function value:connect_signal() end
        function value:emit_signal() end
        function value:set_text(text) self.text = text end
        function value:set_markup(markup) self.markup = markup end
        function value:get_children_by_id(id)
            local found = {}
            local function visit(current)
                if current.id == id then found[#found + 1] = current end
                for _, child in ipairs(current.children) do visit(child) end
            end
            visit(self)
            return found
        end
        nodes[#nodes + 1] = value
        return value
    end
    local function height(value)
        if value.visible == false then return 0 end
        if value.forced_height then return value.forced_height end
        if value.font then return metrics.line_height(value.font) end
        local total, count = 0, 0
        for _, child in ipairs(value.children) do
            if child.visible ~= false then
                count = count + 1
                total = value.layout == 'vertical' and total + height(child) or math.max(total, height(child))
            end
        end
        if value.layout == 'vertical' then total = total + math.max(0, count - 1) * (value.spacing or 0) end
        return total + 2 * (value.margins or 0) + (value.top or 0) + (value.bottom or 0)
    end
    local base = { fit_widget = function(_, _, child, width) return width, height(child) end }
    package.loaded.wibox = {
        widget = setmetatable({ textbox = 'text', imagebox = 'image', base = base }, {
            __call = function(_, spec) return node(spec) end,
        }),
        container = { margin = 'margin', background = 'background', constraint = 'constraint' },
        layout = { fixed = { vertical = 'vertical', horizontal = 'horizontal' }, align = {}, stack = 'stack' },
    }
    package.loaded['wibox.widget.base'] = base
    local timer = setmetatable({ start_new = function() return { stop = function() end } end }, {
        __call = function() return { start = function() end, stop = function() end } end,
    })
    package.loaded.gears = {
        filesystem = { get_configuration_dir = function() return directory end },
        table = { join = function(...) return { ... } end }, shape = {}, timer = timer,
        string = { xml_escape = function(text) return text end },
    }
    local function request(_, callback) requests[#requests + 1] = callback end
    package.loaded.awful = {
        button = function() end, spawn = { easy_async = request, easy_async_with_shell = request },
    }
    package.loaded.naughty = { notification = function() end }
    package.loaded['library.email-refresh'] = { new = function() return function() end end }
    package.loaded['widget.clickable-container'] = 'clickable'
    package.loaded['configuration.config'] = { widget = { calendar_events = {} } }
    package.loaded.beautiful = {
        xresources = {
            get_dpi = function() return resolution end,
            apply_dpi = function(v) return v * resolution / 96 end,
        },
        font_regular = fonts.font_regular, font_bold = fonts.font_bold,
        background = '#111111', groups_bg = '#222222', fg_normal = '#ffffff', bg_focus = '#333333', accent = '#123456',
    }
    awesome = { connect_signal = function(name, callback) signals[name] = callback end }
    package.loaded['widget.email'] = nil
    require('widget.email')
    signals['module::email:show']()
    requests[#requests]('Unread Count: 1\nFrom: Synthetic Sender\nSubject: Synthetic subject\n' ..
        'Local Date: 2026-10-29\n', '', 'exit', 0)
    package.loaded['widget.calendar-events'] = nil
    local calendar = require('widget.calendar-events')
    requests[#requests]('{"ok":true,"events":[{"subject":"Synthetic long calendar title","is_all_day":true}]}')
    local checked = 0
    for _, widget in ipairs(nodes) do
        if widget.font and widget.forced_height then
            assert(widget.forced_height >= metrics.line_height(widget.font), 'Font clipped at DPI ' .. dpi)
            checked = checked + 1
            if widget.markup and widget.markup:find('Synthetic long calendar title', 1, true) then
                assert(widget.forced_height >= metrics.lines(widget.font, 2), 'Two-line calendar title clipped')
            end
        end
    end
    assert(checked >= 6, 'The actual email/calendar text widgets were not exercised')
    assert(calendar:get_minimum_viewport_height() > 0, 'Calendar must reserve a full card')
    local description = Pango.FontDescription.from_string(fonts.font_emoji(12))
    assert(description:get_size() == 12 * Pango.SCALE, 'Fallback font description lost its point size')
    assert(description:get_family():find('Noto Color Emoji', 1, true))
    print('Real-font email/calendar and fallback sizing passed at ' .. dpi .. ' DPI')
end

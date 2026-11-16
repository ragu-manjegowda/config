local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local calls, timer, visibility = {}, nil, nil
local function widget(spec)
    function spec:buttons() end
    function spec:set_text(value) self.text = value end
    function spec:set_image(value) self.image = value end
    for _, child in ipairs(spec) do
        if type(child) == 'table' and child.id then spec[child.id] = widget(child) end
    end
    return spec
end
package.loaded.wibox = {
    widget = setmetatable({}, { __call = function(_, spec) return widget(spec) end }),
    container = {}, layout = { fixed = {}, align = {} },
}
package.loaded.beautiful = {
    xresources = { apply_dpi = function(value) return value end },
    font_bold = function() return '' end, font_regular = function() return '' end,
}
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return root end },
    shape = {}, table = { join = function(...) return { ... } end },
    timer = function(spec)
        timer = spec
        function spec:start() self.started = true end
        function spec:stop() self.started = false end
        return spec
    end,
}
package.loaded.awful = {
    button = function() end,
    spawn = { easy_async = function(argv, callback)
        assert(table.concat(argv, ' ') == 'rfkill list bluetooth')
        calls[#calls + 1] = callback
    end },
}
package.loaded['widget.clickable-container'] = {}
awesome = { connect_signal = function(name, callback)
    assert(name == 'control_center::visibility')
    visibility = callback
end }
require('widget.bluetooth-toggle')
assert(#calls == 0 and not timer.started, 'Hidden Bluetooth widget must not poll at startup')
visibility(true)
assert(#calls == 1 and timer.started)
timer.callback()
assert(#calls == 1, 'Slow Bluetooth queries must not overlap')
visibility(false)
calls[1]('Soft blocked: no')
assert(not timer.started, 'A late query completion must not restart hidden polling')
visibility(true)
assert(#calls == 2 and timer.started)
calls[2]('Soft blocked: yes')
timer.callback()
assert(#calls == 3)
visibility(false)
calls[3]('Soft blocked: no')
assert(not timer.started)
print('Bluetooth visibility, in-flight guard and late-completion tests passed')

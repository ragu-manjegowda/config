local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
local theme = { background = 'panel', accent = 'on' }
package.loaded.beautiful = theme
local bindings = require('theme.bindings')
local new_card = bindings.widget(function() return { visible = true } end, { bg = 'background' })
local card = new_card()
assert(card.bg == 'panel')
bindings.bind(card, { bg = 'accent' })
theme.background, theme.accent = 'new panel', 'still on'
bindings.refresh()
assert(card.visible and card.bg == 'still on')
local weak = setmetatable({}, { __mode = 'v' })
local function removed_screen()
    local widget = new_card()
    bindings.on_change(widget, function(target) target.updated = true end)
    weak[1] = widget
end
removed_screen()
collectgarbage('collect')
collectgarbage('collect')
assert(weak[1] == nil, 'Theme bindings must not retain removed widgets')

local calls = 0
theme.init = function(palette)
    calls = calls + 1
    assert(palette.mode == 'dark')
end
local noop = function() end
package.loaded['theme.default-theme'] = { theme = {}, awesome_overrides = noop }
package.loaded['theme.solarized-dark-theme'] = { theme = { mode = 'dark' }, awesome_overrides = noop }
for _, source in ipairs({
    function() return nil end,
    function() return { lookup = function() return nil end } end,
    function() return { lookup = function() return { has_key = function() return false end } end } end,
}) do
    package.loaded.lgi = { Gio = { SettingsSchemaSource = { get_default = source } } }
    package.loaded.theme = nil
    local controller = require('theme')
    controller.start()
    controller.start()
end
assert(calls == 3, 'Missing schema/key must initialize dark exactly once')
print('Theme role, widget lifetime and missing-settings tests passed')

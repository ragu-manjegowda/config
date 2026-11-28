local root = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path
assert(os.getenv('GSETTINGS_BACKEND') == 'memory', 'Use an isolated GSettings backend')
local lgi = require('lgi')
local Gio, GLib = lgi.Gio, lgi.GLib
local settings = Gio.Settings.new('org.gnome.desktop.interface')
local context = GLib.MainContext.default()
local function prefer(value)
    assert(settings:set_string('color-scheme', value))
    while context:iteration(false) do end
end

local filesystem = { get_configuration_dir = function() return root end }
package.loaded['gears.filesystem'] = filesystem
package.loaded.gears = { filesystem = filesystem, shape = {} }
local palette, switches = {}, 0
local beautiful = setmetatable({
    xresources = { apply_dpi = function(value) return value end },
    init = function(value) palette, switches = value, switches + 1 end,
}, { __index = function(_, key) return palette[key] end })
package.loaded.beautiful = beautiful
prefer('prefer-light')
local theme = require('theme')
theme.start()
theme.start()
assert(beautiful.fg_normal == '#073642' and switches == 1)

local symbolic = require('theme.symbolic')
local box = symbolic.attach({
    _private = {},
    set_image = function(self, image)
        self.rendered = image; return true
    end,
})
local bindings = require('theme.bindings')
local button = bindings.bind({}, { bg = 'background' })
bindings.bind(button, { bg = 'accent' })
local directory = assert(GLib.dir_make_tmp('awesome-theme-XXXXXX'))
local path = directory .. '/glyph.svg'
local original = [[<svg xmlns="http://www.w3.org/2000/svg" width="4" height="1">
<rect width="1" height="1" fill="#073642"/><rect x="1" width="1" height="1" style="fill:#073642"/>
<rect x="2" width="1" height="1" fill="#dc322f"/><rect x="3" width="1" height="1" style="fill:#eee8d5"/></svg>]]
local fixture = assert(io.open(path, 'w'))
fixture:write(original)
fixture:close()
local function pixels(image)
    return image:get_pixbuf():get_pixels()
end
local function check(ink)
    local pixel = string.char(tonumber(ink:sub(2, 3), 16), tonumber(ink:sub(4, 5), 16),
        tonumber(ink:sub(6, 7), 16), 255)
    assert(pixels(box.rendered) == pixel .. pixel .. string.char(220, 50, 47, 255) .. pixel)
    assert(button.bg == beautiful.accent)
end
assert(box:set_image(path))
check('#073642')
local artwork = assert(lgi.Rsvg.Handle.new_from_file(path))
local untouched = pixels(artwork)
prefer('prefer-dark')
check('#eee8d5')
prefer('default')
assert(switches == 2)
assert(box:set_image(root .. 'widget/bluetooth-toggle/icons/bluetooth-off.svg'))
local dark_off = pixels(box.rendered)
prefer('prefer-light')
assert(pixels(box.rendered) ~= dark_off)
prefer('prefer-dark')
assert(pixels(box.rendered) == dark_off and switches == 4)
assert(pixels(artwork) == untouched)
local saved = assert(io.open(path))
assert(saved:read('*a') == original)
saved:close()
assert(os.remove(path))
assert(os.remove(directory))
print('Live GSettings, stateful icon pixels, artwork and palette round-trip passed: ' .. _VERSION)

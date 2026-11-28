local beautiful = require('beautiful')
local bindings = require('theme.bindings')
local theme = {}
local settings, active

local function apply(preference)
    local mode = preference == 'prefer-light' and 'light' or 'dark'
    if mode == active then return end
    local defaults = require('theme.default-theme')
    local variant = require('theme.solarized-' .. mode .. '-theme')
    local palette = {}
    for key, value in pairs(defaults.theme) do palette[key] = value end
    for key, value in pairs(variant.theme) do palette[key] = value end
    defaults.awesome_overrides(palette)
    variant.awesome_overrides(palette)
    beautiful.init(palette)
    active = mode
    bindings.refresh()
end

function theme.start()
    if active then return end
    local Gio = require('lgi').Gio
    local source = Gio.SettingsSchemaSource.get_default()
    local schema = source and source:lookup('org.gnome.desktop.interface', true)
    if not schema or not schema:has_key('color-scheme') then
        apply(nil)
        return
    end
    settings = Gio.Settings.new_full(schema, nil, nil)
    local function changed()
        apply(settings:get_string('color-scheme'))
    end
    settings.on_changed['color-scheme'] = changed
    changed()
end

return theme

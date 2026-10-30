-- Font sizes are points; measure the rendered line at its owning screen's DPI.
local beautiful = require('beautiful')
local lgi = require('lgi')
local Pango, PangoCairo = lgi.Pango, lgi.PangoCairo
local metrics = {}
local cache = {}

function metrics.line_height(font, screen_or_dpi)
    local resolution = type(screen_or_dpi) == 'number' and screen_or_dpi or
        beautiful.xresources.get_dpi(screen_or_dpi)
    local key = font .. '\0' .. tostring(resolution)
    if not cache[key] then
        local context = PangoCairo.FontMap.get_default():create_context()
        PangoCairo.context_set_resolution(context, resolution)
        local layout = Pango.Layout.new(context)
        layout:set_font_description(Pango.FontDescription.from_string(font))
        layout:set_text('Ag', -1)
        local _, height = layout:get_pixel_size()
        cache[key] = math.max(1, math.ceil(height))
    end
    return cache[key]
end

function metrics.lines(font, count, screen_or_dpi)
    return metrics.line_height(font, screen_or_dpi) * (count or 1)
end

return metrics

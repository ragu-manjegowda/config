local bindings = require('theme.bindings')
local beautiful = require('beautiful')
local cache = setmetatable({}, { __mode = 'k' })
local symbolic = {}

local function render(source, ink, silhouette)
    local variants = cache[source] or setmetatable({}, { __mode = 'v' })
    cache[source] = variants
    local key = (silhouette and 'mask:' or 'ink:') .. ink
    if variants[key] then return variants[key] end
    local image
    if not silhouette and type(source) == 'string' and source:match('%.svg$') then
        local handle = require('lgi').Rsvg.Handle.new_from_file(source)
        if not handle then return nil end
        local selectors = '[fill="#eee8d5"], [style*="fill:#eee8d5"], [fill="#073642"], [style*="fill:#073642"]'
        handle:set_stylesheet(selectors .. ' { fill: ' .. ink .. ' !important; }')
        image = handle
    else
        local cairo = require('lgi').cairo
        image = require('gears.surface').duplicate_surface(source)
        local context = cairo.Context(image)
        context.operator = cairo.Operator.IN
        context:set_source(require('gears.color')(ink))
        context:paint()
    end
    variants[key] = image
    return image
end

local function repaint(box)
    local source = box._private.symbolic_source
    local role
    if type(source) == 'table' and source.path then
        role, source = source.role, source.path
    end
    local image = source and render(source, beautiful[role or 'fg_normal'], role ~= nil)
    if source and not image then return false end
    return box._private.set_original_image(box, image)
end

function symbolic.attach(box)
    if box._private.set_original_image then return box end
    box._private.set_original_image = box.set_image
    function box:set_image(source)
        self._private.symbolic_source = source
        return repaint(self)
    end

    local original = box._private.original_image
    if original then box:set_image(original) end
    return bindings.on_change(box, repaint)
end

function symbolic.imagebox()
    return symbolic.attach(require('wibox').widget.imagebox())
end

return symbolic

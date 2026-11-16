local surface = require('gears.surface')
local profile = {}

function profile.square(image)
    return surface.crop_surface {
        surface = surface.load_uncached(image),
        ratio = 1,
    }
end

return profile

local directory = assert(os.getenv('HOME')) .. '/.config/awesome/'
package.path = directory .. '?.lua;' .. package.path
local loaded, cropped
package.loaded['gears.surface'] = {
    load_uncached = function(image)
        loaded = { source = image }
        return loaded
    end,
    crop_surface = function(options)
        assert(options.surface == loaded)
        assert(options.ratio == 1, 'avatars must center-crop to a square without stretching')
        cropped = { source = options.surface }
        return cropped
    end,
}
local profile = require('library.profile-image')
for _, source in ipairs({ 'portrait.png', 'landscape.jpg', 'square.png', 'default.svg', {} }) do
    assert(profile.square(source) == cropped)
    assert(loaded.source == source, 'the selected image must reach the cropper unchanged')
end
local first = profile.square('portrait.png')
local second = profile.square('portrait.png')
assert(first ~= second, 'updated profile images must not reuse stale cached pixels')

for _, name in ipairs({ 'module/lockscreen.lua', 'module/exit-screen.lua', 'widget/user-profile/init.lua' }) do
    local input = assert(io.open(directory .. name))
    local contents = input:read('*a')
    input:close()
    assert(contents:find("require('library.profile-image')", 1, true), name .. ' bypasses shared avatar cropping')
    assert(contents:find("halign = 'center'", 1, true) and contents:find("valign = 'center'", 1, true))
    assert(contents:match('forced_width = dpi%((%d+)%)') == contents:match('forced_height = dpi%((%d+)%)'),
        name .. ' must reserve a square avatar slot')
end

print('profile image tests passed: shared square crop, fresh pixels and square centered avatar slots')

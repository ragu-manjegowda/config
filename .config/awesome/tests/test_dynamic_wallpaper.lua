-- Exercise the actual wallpaper module with a deterministic clock and Gio listing.
-- Test-only override of the read-only os.date function.
-- luacheck: ignore 122
local home = os.getenv('HOME') or ''
local wallpaper_dir = home .. '/.config/awesome/theme/wallpapers/'
local now = '14:30:00'
local current_wallpaper
local applied = {}
local panorama, spans = false, 0
local timer
local signals = {}
local beautiful = {}

local Gio = {
    FileQueryInfoFlags = { NONE = 0 },
    File = {
        new_for_path = function(path)
            assert(path == wallpaper_dir, 'wallpaper directory changed unexpectedly')
            return {
                enumerate_children = function(_, attributes)
                    assert(attributes == 'standard::name,standard::type')
                    local names = { 'am_08.jpg', 'pm_02.jpg', 'pm_03.jpg', 'AUTHORS' }
                    local index = 0
                    return {
                        next_file = function()
                            index = index + 1
                            local name = names[index]
                            if not name then return nil end
                            return {
                                get_name = function() return name end,
                                get_file_type = function() return name == 'AUTHORS' and 'DIRECTORY' or 'REGULAR' end,
                            }
                        end,
                        close = function() end,
                    }
                end,
            }
        end,
    },
}

package.loaded.lgi = { Gio = Gio }
package.loaded.gears = {
    filesystem = { get_configuration_dir = function() return home .. '/.config/awesome/' end },
    wallpaper = {
        maximized = function(path, s, ignore_aspect)
            assert((s ~= nil) == (not panorama), 'Wallpaper scope does not match the panorama setting')
            assert(ignore_aspect == false, 'Wallpaper aspect ratio must be preserved')
            if s then applied[s] = path else spans = spans + 1 end
            current_wallpaper = path
        end
    },
    debug = { print_error = function(message) error(message) end },
    timer = function(options)
        timer = options
        function timer:again() self.restarted = true end

        return timer
    end,
}
package.loaded.beautiful = beautiful
package.loaded['configuration.config'] = {
    module = {
        dynamic_wallpaper = {
            wall_dir = 'theme/wallpapers/',
            valid_picture_formats = { 'jpg' },
            wallpaper_schedule = {
                ['08:00:00'] = 'am_08.jpg',
                ['14:00:00'] = 'pm_02.jpg',
                ['15:00:00'] = 'pm_03.jpg',
            },
            stretch = false,
        }
    },
}

awesome = {
    connect_signal = function(name, callback) signals[name] = callback end,
    emit_signal = function(name) if signals[name] then signals[name]() end end,
}

local primary = { geometry = { width = 2880, height = 1800 } }
local external = { geometry = { width = 3440, height = 1440 } }
local geometry_handler
screen = setmetatable({
    connect_signal = function(name, handler)
        assert(name == 'property::geometry'); geometry_handler = handler
    end
}, {
    __call = function(_, _, previous)
        if not previous then return primary end
        if previous == primary then return external end
    end
})

local date = os.date
os.date = function(format, ...)
    if format == '%H:%M:%S' then return now end
    return date(format, ...)
end

local wallpaper = dofile(home .. '/.config/awesome/module/dynamic-wallpaper.lua')
assert(get_wallpaper_name() == 'pm_02.jpg', 'startup did not select the afternoon wallpaper')
assert(current_wallpaper == wallpaper_dir .. 'pm_02.jpg', 'startup did not apply the selected wallpaper')
assert(beautiful.wallpaper == current_wallpaper, 'new screens lost the selected wallpaper')
assert(timer.timeout == 1800 and timer.autostart, 'next wallpaper change was not scheduled')
assert(applied[primary] == current_wallpaper and applied[external] == current_wallpaper,
    'Each screen must get an independent aspect-preserving wallpaper')
applied[external] = nil
external.geometry.height = 1080
geometry_handler(external)
assert(applied[external] == current_wallpaper, 'Resized screen lost its wallpaper')
local added = { geometry = { width = 1920, height = 1080 } }
wallpaper.apply(added)
assert(applied[added] == current_wallpaper, 'New screen did not get its own wallpaper')

now = '15:00:00'
timer.callback()
assert(get_wallpaper_name() == 'pm_03.jpg', 'scheduled change did not advance the wallpaper')
assert(current_wallpaper == wallpaper_dir .. 'pm_03.jpg', 'scheduled change did not apply the wallpaper')
assert(timer.restarted and timer.timeout == 17 * 3600, 'timer was not rescheduled for tomorrow')
assert(applied[primary] == current_wallpaper and applied[external] == current_wallpaper,
    'Scheduled changes must keep fitting every screen independently')

panorama = true
package.loaded['configuration.config'].module.dynamic_wallpaper.stretch = true
wallpaper = dofile(home .. '/.config/awesome/module/dynamic-wallpaper.lua')
assert(spans == 1, 'Explicit panorama mode must render once across the root desktop')
wallpaper.apply(external)
assert(spans == 2, 'Panorama mode must remain consistent when a screen requests wallpaper')

os.date = date
print('dynamic wallpaper tests passed')

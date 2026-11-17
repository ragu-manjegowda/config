local directory = assert(os.getenv('HOME')) .. '/.config/awesome/'
local input = assert(io.open(directory .. 'module/lockscreen.lua'))
local source = input:read('*a')
input:close()
local implementation = assert(source:match('(local filter_bg_image = function.-)\nawesome.connect_signal%('))
local wallpaper = 'weather/cloudy/noon.jpg'
local target = {}
local display = { index = 1, valid = true, geometry = { width = 1920, height = 1080 }, target = target }
local options = { bg_dir = '/wall papers/', tmp_wall_dir = '/cache dir/', blur_background = false }
local commands, callbacks, parents, errors = {}, {}, {}, {}
local parent_ok, readable, spawn_ok = true, true, true
local environment = setmetatable({
    locker_config = options,
    screen = function(_, previous) if not previous then return display end end,
    lockscreen_for_screen = function(screen) return screen.valid and screen.target or nil end,
    get_wallpaper_name = function() return wallpaper end,
    filesystem = {
        make_parent_directories = function(path)
            parents[#parents + 1] = path
            return parent_ok, 'permission denied'
        end,
        file_readable = function() return readable end,
    },
    gears = {
        debug = { print_error = function(message) errors[#errors + 1] = message end },
        surface = { load_uncached = function(path) return { path = path } end },
    },
    awful = {
        spawn = {
            easy_async = function(command, callback)
                if not spawn_ok then return 'injected spawn error' end
                commands[#commands + 1] = command
                callbacks[#callbacks + 1] = callback
                return 123
            end
        }
    },
}, { __index = _G })
local chunk
if setfenv then
    chunk = assert(loadstring(implementation .. '\nreturn apply_ls_bg_image'))
    setfenv(chunk, environment)
else
    chunk = assert(load(implementation .. '\nreturn apply_ls_bg_image', 'lockscreen-background', 't', environment))
end
local apply = chunk()
apply(wallpaper)
local command = commands[#commands]
assert(command[1] == 'magick', 'conversion must use an argv vector rather than a shell')
assert(parents[1] == '/cache dir/1-weather/cloudy/noon.jpg',
    'must create all output parents, including nested weather directories')
assert(command[#command] == parents[1], 'directory creation and conversion must use the same output path')
assert(command[2] == '/wall papers/weather/cloudy/noon.jpg', 'paths with spaces must remain one argument')
assert(command[#command - 1] == '1920x1080!', 'conversion must match screen dimensions')
callbacks[#callbacks]('', '', 'exit', 0)
assert(target.bgimage.path == parents[1], 'successful conversion must update the lockscreen')
local previous = target.bgimage
apply(wallpaper)
callbacks[#callbacks]('', '', 'exit', 0)
assert(target.bgimage ~= previous, 'rewritten files must not reuse stale cached pixels')
previous = target.bgimage

apply(wallpaper)
callbacks[#callbacks]('', 'injected conversion failure', 'exit', 1)
assert(target.bgimage == previous and errors[#errors]:match('injected conversion failure'),
    'failed conversions must preserve the current image and log stderr')
apply(wallpaper)
wallpaper = 'weather/rain/noon.jpg'
callbacks[#callbacks]('', '', 'exit', 0)
assert(target.bgimage == previous, 'late results must not replace a newer wallpaper selection')
apply(wallpaper)
display.geometry.width = 2560
callbacks[#callbacks]('', '', 'exit', 0)
assert(target.bgimage == previous, 'late results must not apply obsolete screen dimensions')
apply(wallpaper)
readable = false
callbacks[#callbacks]('', '', 'exit', 0)
assert(target.bgimage == previous, 'missing conversion output must preserve the previous image')
readable = true

local count = #commands
parent_ok = false
apply(wallpaper)
assert(#commands == count and errors[#errors]:match('permission denied'),
    'directory creation errors must be reported without launching conversion')
parent_ok = true
spawn_ok = false
apply(wallpaper)
assert(errors[#errors]:match('injected spawn error'), 'process launch failures must be logged')
spawn_ok = true
apply(wallpaper)
display.target = {}
callbacks[#callbacks]('', '', 'exit', 0)
assert(target.bgimage == previous and not display.target.bgimage, 'replaced lockscreen must ignore old results')
apply(wallpaper)
display.valid = false
callbacks[#callbacks]('', '', 'exit', 0)
assert(not display.target.bgimage, 'removed screens must ignore old results')

display.valid = true
options.blur_background = true
apply(wallpaper)
assert(table.concat(commands[#commands], ' '):find('-filter Gaussian -blur 0x10', 1, true),
    'optional background blur must remain supported')
count = #commands
apply(nil)
apply('')
assert(#commands == count, 'empty selections must not launch conversion')
print('lockscreen background tests passed: nested paths, fresh pixels, failures and stale results')

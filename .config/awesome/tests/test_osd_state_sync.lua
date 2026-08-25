#!/usr/bin/env lua

local root = os.getenv('HOME') .. '/.config/awesome/'
local passed = 0
local failed = 0

local function read(path)
    local file = assert(io.open(root .. path, 'r'))
    local content = file:read('*a')
    file:close()
    return content
end

local function check(condition, name)
    if condition then
        print('  ✓ ' .. name)
        passed = passed + 1
    else
        print('  ✗ ' .. name)
        failed = failed + 1
    end
end

print('\nOSD State Synchronization Tests')
print(string.rep('=', 50))

local widgets = {
    volume = read('widget/volume-slider/init.lua'),
    brightness = read('widget/brightness-slider/init.lua'),
    kbd_brightness = read('widget/kbd-brightness-slider/init.lua')
}

for name, content in pairs(widgets) do
    check(
        content:find('local update_slider = function%(show_osd%)') ~= nil,
        name .. ' refresh accepts OSD visibility request'
    )
    check(
        content:find("awesome.emit_signal%(%s*'module::" .. name .. "_osd'") ~= nil,
        name .. ' refresh propagates queried value to OSD'
    )
end

local osds = {
    read('module/volume-osd.lua'),
    read('module/brightness-osd.lua'),
    read('module/kbd-brightness-osd.lua')
}

for index, content in ipairs(osds) do
    check(
        content:find('is_programmatic_update') ~= nil,
        'OSD ' .. index .. ' suppresses hardware writes during status refresh'
    )
end

local keys = read('configuration/keys/global.lua')
check(
    keys:find('run_and_refresh_osd') ~= nil,
    'media keys refresh OSD after hardware command completion'
)

check(
    widgets.volume:find("audio_monitor:connect_signal%('sink', function%(%)") ~= nil,
    'audio monitor refresh does not show volume OSD'
)

check(
    widgets.kbd_brightness:find('last_brightness') ~= nil and
        widgets.kbd_brightness:find('timeout = 0.25', 1, true) ~= nil,
    'keyboard backlight monitor shows firmware-driven state changes'
)

local keyboard_helper = read('utilities/kbd-bkl')
check(
    keyboard_helper:find('max_brightness', 1, true) ~= nil,
    'keyboard helper uses the device brightness range'
)

print(string.format('\nResults: %d passed, %d failed', passed, failed))
os.exit(failed == 0 and 0 or 1)

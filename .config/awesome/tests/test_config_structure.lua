#!/usr/bin/env lua
-- Unit tests for overall config structure
-- Run with: lua tests/test_config_structure.lua

local TEST_NAME = "Configuration Structure Tests"
local tests_passed = 0
local tests_failed = 0

-- Setup
local home = os.getenv("HOME")
package.path = home .. "/.config/awesome/?.lua;" ..
    home .. "/.config/awesome/?/init.lua;" ..
    package.path

package.loaded['gears.filesystem'] = {
    get_configuration_dir = function()
        return home .. "/.config/awesome/"
    end
}

-- Helper functions
local function assert_test(condition, test_name, message)
    if condition then
        print("  ✓ " .. test_name)
        tests_passed = tests_passed + 1
        return true
    else
        print("  ✗ " .. test_name)
        if message then
            print("    " .. message)
        end
        tests_failed = tests_failed + 1
        return false
    end
end

local function assert_not_nil(value, test_name)
    return assert_test(value ~= nil, test_name, "Value is nil")
end

local function assert_type(value, expected_type, test_name)
    return assert_test(
        type(value) == expected_type,
        test_name,
        string.format("Expected type '%s', got '%s'", expected_type, type(value))
    )
end

print("\n" .. TEST_NAME)
print(string.rep("=", 50))

-- Load configuration
local success, config = pcall(require, 'configuration.config')
if not success then
    print("❌ Failed to load configuration.config")
    print(config)
    os.exit(1)
end

-- Test: Top-level structure
print("\nTest Suite: Top-Level Structure")
assert_not_nil(config, "config module loads")
assert_type(config, "table", "config is a table")

-- Test: Major sections exist
print("\nTest Suite: Major Configuration Sections")
local required_sections = {
    "display",
    "keyboard",
    "widget",
    "module",
}

for _, section in ipairs(required_sections) do
    assert_not_nil(config[section], section .. " section exists")
    assert_type(config[section], "table", section .. " is a table")
end

-- Test: Widget configuration
print("\nTest Suite: Widget Configuration")
if config.widget then
    local expected_widgets = {
        "email",
        "weather",
        "clock",
        "screen_recorder",
        "stocks",
        "calendar_events",
    }

    for _, widget in ipairs(expected_widgets) do
        if config.widget[widget] then
            assert_type(config.widget[widget], "table", "widget." .. widget .. " is a table")
        else
            print("  ⚠ widget." .. widget .. " not configured (may be optional)")
        end
    end
end

-- Test: Stocks configuration
print("\nTest Suite: Stocks Configuration")
if config.widget and config.widget.stocks then
    local stocks = config.widget.stocks

    if stocks.symbols then
        assert_type(stocks.symbols, "table", "stocks.symbols is a table")
        assert_test(#stocks.symbols > 0, "stocks.symbols is not empty")
    end

    if stocks.update_interval then
        assert_type(stocks.update_interval, "number", "stocks.update_interval is a number")
        assert_test(
            stocks.update_interval >= 60,
            "stocks.update_interval >= 60 seconds (reasonable rate limit)"
        )
    end
end

-- Test: Calendar Events configuration
print("\nTest Suite: Calendar Events Configuration")
if config.widget and config.widget.calendar_events then
    local cal = config.widget.calendar_events

    assert_not_nil(cal.script, "calendar_events.script is defined")
    if cal.script then
        assert_type(cal.script, "string", "calendar_events.script is a string")
        assert_test(
            cal.script:match("outlook%-calendar$") ~= nil,
            "calendar_events.script points to outlook-calendar"
        )

        local f = io.open(cal.script, "r")
        if f then
            local first_line = f:read("*l") or ""
            f:close()
            assert_test(
                first_line:match("python") ~= nil,
                "calendar_events.script is a Python script (not git-crypt blob)"
            )
        else
            print("  ⚠ calendar_events.script file not found at: " .. cal.script)
        end
    end

    if cal.window_days then
        assert_type(cal.window_days, "number", "calendar_events.window_days is a number")
        assert_test(
            cal.window_days >= 1 and cal.window_days <= 14,
            "calendar_events.window_days is in reasonable range (1-14)"
        )
    end

    if cal.max_items ~= nil then
        assert_type(cal.max_items, "number", "calendar_events.max_items is a number")
    end

    if cal.show_cancelled ~= nil then
        assert_type(cal.show_cancelled, "boolean", "calendar_events.show_cancelled is a boolean")
    end
end

-- Test: Module configuration
print("\nTest Suite: Module Configuration")
if config.module then
    local expected_modules = {
        "auto_start",
        "dynamic_wallpaper",
        "lockscreen",
    }

    for _, mod in ipairs(expected_modules) do
        if config.module[mod] then
            assert_type(config.module[mod], "table", "module." .. mod .. " is a table")
        else
            print("  ⚠ module." .. mod .. " not configured (may be optional)")
        end
    end
end

-- Test: Keyboard configuration
print("\nTest Suite: Keyboard Configuration")
if config.keyboard then
    assert_test(
        config.keyboard.file ~= nil,
        "keyboard.file is defined"
    )

    if config.keyboard.file then
        assert_type(config.keyboard.file, "string", "keyboard.file is a string")
        assert_test(
            config.keyboard.file:match("^/"),
            "keyboard.file is absolute path"
        )
    end

    if config.keyboard.script then
        assert_type(config.keyboard.script, "string", "keyboard.script is a string")
    end
end

-- Test: Screen recorder configuration
print("\nTest Suite: Screen Recorder Configuration")
if config.widget and config.widget.screen_recorder then
    local sr = config.widget.screen_recorder

    if sr.display_target then
        assert_test(
            sr.display_target == 'primary' or sr.display_target == 'external' or sr.display_target == 'both',
            "screen_recorder.display_target is 'primary', 'external', or 'both'",
            "Got: " .. sr.display_target
        )
    end

    if sr.fps then
        assert_type(sr.fps, "string", "screen_recorder.fps is a string")
        local fps_num = tonumber(sr.fps)
        if fps_num then
            assert_test(
                fps_num >= 24 and fps_num <= 120,
                "FPS is in reasonable range (24-120)"
            )
        end
    end
end

-- Test: Screenshot configuration
print("\nTest Suite: Screenshot Configuration")
if config.widget and config.widget.screenshot then
    local ss = config.widget.screenshot

    if ss.display_target then
        assert_test(
            ss.display_target == 'primary' or ss.display_target == 'external' or ss.display_target == 'both',
            "screenshot.display_target is 'primary', 'external', or 'both'",
            "Got: " .. ss.display_target
        )
    end
end

-- Test: Weather configuration
print("\nTest Suite: Weather Configuration")
if config.widget and config.widget.weather then
    local weather = config.widget.weather

    if weather.update_interval then
        assert_type(weather.update_interval, "number", "update_interval is a number")
        assert_test(
            weather.update_interval >= 60,
            "update_interval >= 60 seconds (reasonable rate limit)"
        )
    end

    if weather.units then
        assert_test(
            weather.units == "metric" or weather.units == "imperial",
            "units is 'metric' or 'imperial'",
            "Got: " .. tostring(weather.units)
        )
    end
end

-- Test: Lockscreen configuration
print("\nTest Suite: Lockscreen Configuration")
if config.module and config.module.lockscreen then
    local lock = config.module.lockscreen

    if lock.capture_intruder ~= nil then
        assert_type(lock.capture_intruder, "boolean", "capture_intruder is a boolean")
    end
    if lock.fingerprint_unlock ~= nil then
        assert_type(lock.fingerprint_unlock, "boolean", "fingerprint_unlock is a boolean")
    end
    if lock.capture_intruder then
        assert_test(lock.camera_device == "/dev/video90",
            "intruder capture uses the compatibility camera",
            "Expected /dev/video90, got " .. tostring(lock.camera_device))
    end

    if lock.military_clock ~= nil then
        assert_type(lock.military_clock, "boolean", "military_clock is a boolean")
    end

    if lock.camera_device then
        assert_test(
            lock.camera_device:match("^/dev/"),
            "camera_device starts with /dev/"
        )
    end
end

local client_buttons = assert(io.open(
    home .. '/.config/awesome/configuration/client/buttons.lua',
    'r'
))
local client_button_source = client_buttons:read('*a')
client_buttons:close()
assert_test(
    client_button_source:match("c:activate%s*{%s*context%s*=%s*'mouse_click'%s*}") ~= nil and
    client_button_source:match("c:emit_signal%('request::activate'%)") == nil,
    "client clicks use Awesome's grab-aware activation path"
)

local tags_file = assert(io.open(
    home .. '/.config/awesome/configuration/tags/init.lua',
    'r'
))
local tags_source = tags_file:read('*a')
tags_file:close()
assert_test(
    tags_source:match("tag%.connect_signal%(%s*'property::selected'") ~= nil and
    tags_source:match('attached_connect_signal') == nil,
    "urgent-tag selection is registered without an undefined screen"
)

local wallpaper_file = assert(io.open(
    home .. '/.config/awesome/module/dynamic-wallpaper.lua',
    'r'
))
local wallpaper_source = wallpaper_file:read('*a')
wallpaper_file:close()
assert_test(
    wallpaper_source:match('Gio%.File%.new_for_path') ~= nil and
    wallpaper_source:match('enumerate_children') ~= nil and
    wallpaper_source:match('filesystem%.get_directory_items') == nil and
    wallpaper_source:match('io%.popen') == nil,
    "wallpaper discovery uses Gio directory enumeration"
)

local clock_file = assert(io.open(
    home .. '/.config/awesome/widget/clock/init.lua',
    'r'
))
local clock_source = clock_file:read('*a')
clock_file:close()
assert_test(
    clock_source:match('function widget_button:force_update%(%s*%)[%s%S]-clock:force_update%(%s*%)') ~= nil,
    "panel clock exposes an immediate refresh method"
)

local battery_file = assert(io.open(
    home .. '/.config/awesome/widget/battery/init.lua',
    'r'
))
local battery_source = battery_file:read('*a')
battery_file:close()
assert_test(
    battery_source:match("'Battery: ' %.%. battery_summary %.%. consumer_summary") ~= nil and
        battery_source:match('battery_tooltip:set_markup') ~= nil and
        battery_source:match('font_family="Hack Nerd Font Mono"') ~= nil and
        battery_source:match("field%('energy%-rate'%)") ~= nil and
        battery_source:match('stdout:sub') == nil,
    "battery tooltip is aligned, concise, and estimates discharge time when needed"
)

local email_file = assert(io.open(
    home .. '/.config/awesome/widget/email/init.lua',
    'r'
))
local email_source = email_file:read('*a')
email_file:close()
assert_test(
    email_source:match('local EMAIL_HEIGHT%s*=%s*dpi%(88%)') ~= nil and
        email_source:match('local MAX_HEIGHT%s*=%s*dpi%(155%)') ~= nil and
        email_source:match('local MAX_SUBJECT_LINE_LENGTH%s*=%s*42') ~= nil and
        email_source:match("require%('library%.email%-subject'%)") ~= nil and
        email_source:match('email_subject%.split%(subject, MAX_SUBJECT_LINE_LENGTH%)') ~= nil and
        email_source:match("visible%s*=%s*subject_line_two ~= ''") ~= nil and
        email_source:match("ellipsize%s*=%s*'end'") == nil and
        email_source:match('forced_height%s*=%s*dpi%(12%)') ~= nil,
    "email cards cap subjects at two lines without overlapping timestamps"
)

local calendar_file = assert(io.open(
    home .. '/.config/awesome/widget/calendar-events/init.lua',
    'r'
))
local calendar_source = calendar_file:read('*a')
calendar_file:close()
assert_test(
    calendar_source:match('local MAX_HEIGHT%s*=%s*EVENT_HEIGHT %* 2 %+ EVENT_SPACING %* 2') ~= nil and
        calendar_source:match('local EVENT_STRIDE%s*=%s*EVENT_HEIGHT %+ EVENT_SPACING') ~= nil and
        calendar_source:match('target_offset %- %(EVENT_HEIGHT / 2 %+ EVENT_SPACING%)') ~= nil and
        calendar_source:match("require%('library%.calendar%-snap'%)") ~= nil and
        calendar_source:match('calendar_snap%.build%(row_heights, EVENT_SPACING, MAX_HEIGHT%)') ~= nil and
        calendar_source:match('calendar_snap%.step%(scroll_offset, snap_offsets, direction%)') ~= nil,
    "calendar viewport centers cards with symmetric snap scrolling"
)
assert_test(
    calendar_source:match('local calendar_report%s*=%s*wibox%.widget') ~= nil and
        calendar_source:match('local calendar_report.-margins%s*=%s*dpi%(10%).-' ..
            'bg%s*=%s*beautiful%.groups_bg.-return calendar_report') ~= nil,
    "calendar header and events share the grouped Info Center background"
)
assert_test(
    calendar_source:match('local EVENT_TITLE_HEIGHT%s*=%s*dpi%(28%)') ~= nil and
        calendar_source:match('local EVENT_DETAILS_HEIGHT%s*=%s*dpi%(12%)') ~= nil and
        calendar_source:match("wrap%s*=%s*'word_char'") ~= nil and
        calendar_source:match("ellipsize%s*=%s*'end'") ~= nil and
        calendar_source:match('forced_height%s*=%s*EVENT_TITLE_HEIGHT') ~= nil and
        calendar_source:match('forced_height%s*=%s*EVENT_DETAILS_HEIGHT') ~= nil,
    "calendar cards cap subjects at two lines and preserve event time"
)
assert_test(
    calendar_source:match("awesome%.connect_signal%('info_center::visibility', function%(visible%)") ~= nil and
        calendar_source:match('if visible then%s+refresh%(%)') ~= nil and
        calendar_source:match('local refresh_button%s*=%s*wibox%.widget%s*{%s*{%s*{%s*refresh_icon') ~= nil and
        calendar_source:match('bg%s*=%s*beautiful%.accent') ~= nil and
        calendar_source:match('shape%s*=%s*gears%.shape%.circle') ~= nil and
        calendar_source:match('widget%s*=%s*wibox%.container%.background') ~= nil,
    "calendar refreshes when Info Center opens and uses the accent refresh button"
)

-- Summary
print("\n" .. string.rep("=", 50))
print(string.format("Results: %d passed, %d failed", tests_passed, tests_failed))

if tests_failed > 0 then
    print("❌ Some tests failed")
    os.exit(1)
else
    print("✓ All tests passed!")
    os.exit(0)
end

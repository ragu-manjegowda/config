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
        "network",
        "clock",
        "screen_recorder",
    }

    for _, widget in ipairs(expected_widgets) do
        if config.widget[widget] then
            assert_type(config.widget[widget], "table", "widget." .. widget .. " is a table")
        else
            print("  ⚠ widget." .. widget .. " not configured (may be optional)")
        end
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
            sr.display_target == 'primary' or sr.display_target == 'external',
            "screen_recorder.display_target is 'primary' or 'external'",
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

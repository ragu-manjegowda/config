#!/usr/bin/env lua
-- Unit tests for display configuration
-- Run with: lua tests/test_display_config.lua

local TEST_NAME = "Display Configuration Tests"
local tests_passed = 0
local tests_failed = 0

-- Setup path for loading modules
local home = os.getenv("HOME")
package.path = home .. "/.config/awesome/?.lua;" .. 
               home .. "/.config/awesome/?/init.lua;" .. 
               package.path

-- Mock gears.filesystem
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

local function assert_equals(actual, expected, test_name)
    return assert_test(
        actual == expected,
        test_name,
        string.format("Expected '%s', got '%s'", tostring(expected), tostring(actual))
    )
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

-- Load configuration
print("\n" .. TEST_NAME)
print(string.rep("=", 50))

local success, config = pcall(require, 'configuration.config')
if not success then
    print("❌ Failed to load configuration.config")
    print(config)
    os.exit(1)
end

-- Test: Display config exists
print("\nTest Suite: Display Configuration Structure")
assert_not_nil(config.display, "display config exists")
assert_type(config.display, "table", "display config is a table")

-- Test: DPI setting
print("\nTest Suite: DPI Configuration")
assert_not_nil(config.display.dpi, "dpi is defined")
assert_type(config.display.dpi, "number", "dpi is a number")
assert_test(config.display.dpi > 0, "dpi is positive")
assert_test(config.display.dpi >= 96 and config.display.dpi <= 384, 
    "dpi is in reasonable range (96-384)")

-- Test: Primary display config
print("\nTest Suite: Primary Display Configuration")
assert_not_nil(config.display.primary, "primary display config exists")
assert_type(config.display.primary, "table", "primary is a table")
assert_not_nil(config.display.primary.name, "primary.name exists")
assert_type(config.display.primary.name, "string", "primary.name is a string")
assert_not_nil(config.display.primary.mode, "primary.mode exists")
assert_type(config.display.primary.mode, "string", "primary.mode is a string")
assert_not_nil(config.display.primary.position, "primary.position exists")
assert_type(config.display.primary.position, "string", "primary.position is a string")

-- Test: Primary display values
assert_test(
    config.display.primary.name:match("^[a-zA-Z]"),
    "primary.name starts with letter",
    "Display names typically start with letters (eDP, HDMI, DP, etc.)"
)
assert_test(
    config.display.primary.mode:match("^%d+x%d+$"),
    "primary.mode matches resolution format (WIDTHxHEIGHT)",
    string.format("Got: %s", config.display.primary.mode)
)
assert_test(
    config.display.primary.position:match("^%d+x%d+$"),
    "primary.position matches position format (XxY)",
    string.format("Got: %s", config.display.primary.position)
)

-- Test: External display config
print("\nTest Suite: External Display Configuration")
assert_not_nil(config.display.external, "external display config exists")
assert_type(config.display.external, "table", "external is a table")
assert_not_nil(config.display.external.name, "external.name exists")
assert_type(config.display.external.name, "string", "external.name is a string")
assert_not_nil(config.display.external.mode, "external.mode exists")
assert_type(config.display.external.mode, "string", "external.mode is a string")
assert_not_nil(config.display.external.position, "external.position exists")
assert_type(config.display.external.position, "string", "external.position is a string")

-- Test: External display values
assert_test(
    config.display.external.name:match("^[a-zA-Z]"),
    "external.name starts with letter"
)
assert_test(
    config.display.external.mode:match("^%d+x%d+$"),
    "external.mode matches resolution format",
    string.format("Got: %s", config.display.external.mode)
)
assert_test(
    config.display.external.position:match("^%d+x%d+$"),
    "external.position matches position format",
    string.format("Got: %s", config.display.external.position)
)

-- Test: External display scaling (optional)
if config.display.external.scale_from then
    assert_type(config.display.external.scale_from, "string", "scale_from is a string")
    assert_test(
        config.display.external.scale_from:match("^%d+x%d+$"),
        "scale_from matches resolution format",
        string.format("Got: %s", config.display.external.scale_from)
    )
end

-- Test: Different display names
print("\nTest Suite: Display Name Uniqueness")
assert_test(
    config.display.primary.name ~= config.display.external.name,
    "primary and external have different names",
    "Display names should be unique"
)

-- Test: Resolution values are reasonable
print("\nTest Suite: Resolution Validation")
local function parse_resolution(res_string)
    local width, height = res_string:match("^(%d+)x(%d+)$")
    return tonumber(width), tonumber(height)
end

local prim_w, prim_h = parse_resolution(config.display.primary.mode)
if prim_w and prim_h then
    assert_test(prim_w >= 640, "primary width >= 640")
    assert_test(prim_h >= 480, "primary height >= 480")
    assert_test(prim_w <= 7680, "primary width <= 7680 (8K)")
    assert_test(prim_h <= 4320, "primary height <= 4320 (8K)")
end

local ext_w, ext_h = parse_resolution(config.display.external.mode)
if ext_w and ext_h then
    assert_test(ext_w >= 640, "external width >= 640")
    assert_test(ext_h >= 480, "external height >= 480")
    assert_test(ext_w <= 7680, "external width <= 7680 (8K)")
    assert_test(ext_h <= 4320, "external height <= 4320 (8K)")
end

-- Test: Position values
print("\nTest Suite: Position Validation")
local prim_x, prim_y = parse_resolution(config.display.primary.position)
local ext_x, ext_y = parse_resolution(config.display.external.position)

if prim_x and prim_y and ext_x and ext_y then
    assert_test(prim_x >= 0, "primary x position >= 0")
    assert_test(prim_y >= 0, "primary y position >= 0")
    assert_test(ext_x >= 0, "external x position >= 0")
    assert_test(ext_y >= 0, "external y position >= 0")
    
    -- For extended displays, positions should differ unless stacked
    if ext_x == prim_x and ext_y == prim_y then
        print("  ⚠ Warning: displays have same position (overlapping)")
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


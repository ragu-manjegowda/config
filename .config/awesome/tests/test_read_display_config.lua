#!/usr/bin/env lua
-- Unit tests for read-display-config utility
-- Run with: lua tests/test_read_display_config.lua

local TEST_NAME = "Read Display Config Tests"
local tests_passed = 0
local tests_failed = 0

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

print("\n" .. TEST_NAME)
print(string.rep("=", 50))

-- Test: Script exists and is executable
print("\nTest Suite: Script Availability")
local script_path = os.getenv("HOME") .. "/.config/awesome/utilities/read-display-config"
local stat = io.popen("test -f '" .. script_path .. "' && echo 'exists' || echo 'missing'"):read("*l")
assert_test(stat == "exists", "read-display-config file exists", "Path: " .. script_path)

local exec_stat = io.popen("test -x '" .. script_path .. "' && echo 'executable' || echo 'not-executable'"):read("*l")
assert_test(exec_stat == "executable", "read-display-config is executable")

-- Test: Script outputs bash exports
print("\nTest Suite: Output Format")
local output = io.popen(script_path):read("*a")
assert_test(output ~= "", "script produces output")
assert_test(output:match("export"), "output contains 'export' statements")

-- Test: Required variables are exported
print("\nTest Suite: Required Variables")
local required_vars = {
    "DISPLAY_DPI",
    "PRIMARY_NAME",
    "PRIMARY_MODE",
    "PRIMARY_POS",
    "EXTERNAL_NAME",
    "EXTERNAL_MODE",
    "EXTERNAL_POS",
}

for _, var in ipairs(required_vars) do
    assert_test(
        output:match("export " .. var),
        var .. " is exported",
        "Variable not found in output"
    )
end

-- Test: Values are properly quoted
print("\nTest Suite: Value Formatting")
-- Check for quoted values: export VAR="value"
local has_quoted = output:match('export [%w_]+="[^"]*"')
-- Check for numeric values: export VAR=123
local has_numeric = output:match('export [%w_]+=%d+')
assert_test(
    has_quoted ~= nil and has_numeric ~= nil,
    "values are properly quoted or numeric (both types found)",
    string.format("Quoted: %s, Numeric: %s", tostring(has_quoted ~= nil), tostring(has_numeric ~= nil))
)

-- Test: Can be sourced in bash
print("\nTest Suite: Bash Compatibility")
local bash_test_file = "/tmp/test_read_display_config_" .. os.time() .. ".sh"
local bash_test = "#!/bin/bash\n" ..
    "source <(" .. script_path .. ") 2>/dev/null\n" ..
    'if [ -n "$DISPLAY_DPI" ] && [ -n "$PRIMARY_NAME" ] && [ -n "$EXTERNAL_NAME" ]; then\n' ..
    '    echo "success"\n' ..
    "else\n" ..
    '    echo "failed"\n' ..
    "fi\n"

local f = io.open(bash_test_file, "w")
if f then
    f:write(bash_test)
    f:close()
    os.execute("chmod +x " .. bash_test_file)
    local bash_result = io.popen(bash_test_file .. " 2>&1"):read("*l")
    os.remove(bash_test_file)
    
    assert_test(
        bash_result == "success",
        "script can be sourced in bash",
        bash_result and ("Got: " .. bash_result) or "Failed to source and access variables"
    )
else
    print("  ⚠ Could not create temp test file")
end

-- Test: Values match config.lua
print("\nTest Suite: Value Consistency")
local home = os.getenv("HOME")
package.path = home .. "/.config/awesome/?.lua;" .. 
               home .. "/.config/awesome/?/init.lua;" .. 
               package.path

package.loaded['gears.filesystem'] = {
    get_configuration_dir = function()
        return home .. "/.config/awesome/"
    end
}

local success, config = pcall(require, 'configuration.config')
if success and config.display then
    -- Parse output
    local dpi = output:match("export DISPLAY_DPI=(%d+)")
    local primary_name = output:match('export PRIMARY_NAME="([^"]*)"')
    local external_name = output:match('export EXTERNAL_NAME="([^"]*)"')
    
    if dpi then
        assert_test(
            tonumber(dpi) == config.display.dpi,
            "DPI matches config.lua",
            string.format("Config: %d, Output: %s", config.display.dpi, dpi)
        )
    end
    
    if primary_name then
        assert_test(
            primary_name == config.display.primary.name,
            "PRIMARY_NAME matches config.lua",
            string.format("Config: %s, Output: %s", config.display.primary.name, primary_name)
        )
    end
    
    if external_name then
        assert_test(
            external_name == config.display.external.name,
            "EXTERNAL_NAME matches config.lua",
            string.format("Config: %s, Output: %s", config.display.external.name, external_name)
        )
    end
else
    print("  ⚠ Could not load config.lua for comparison")
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


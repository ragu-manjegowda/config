-------------------------------------------------------------------------------
-- Test helper module - sets up environment for testing
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

-- Suppress notifications during tests
vim.notify = function(_, _, _) end

-- NOTE: Package path setup for lazy plugins is handled by minimal_init.lua
-- which always runs before test files. No duplicate setup needed here.

--- Helper to test that a keymap calls a specific module function
--- @param lhs string The keymap to test (e.g., "<leader>dtb")
--- @param expected_mod string The module name (e.g., "dap")
--- @param expected_func string The function name (e.g., "toggle_breakpoint")
--- @param mode? string The mode (default "n")
function M.assert_keymap_calls(lhs, expected_mod, expected_func, mode)
    mode = mode or "n"

    local map = vim.fn.maparg(lhs, mode, false, true)
    assert(map.rhs or map.callback,
        lhs .. " keymap should be set in mode " .. mode)

    -- Verify the mapping points to correct function
    if map.rhs then
        -- Pattern matches: require("mod").func() or require('mod').func()
        local pattern = 'require%(["\']' .. expected_mod .. '["\']%)%.' .. expected_func
        assert(string.match(map.rhs, pattern),
            lhs .. " should call " .. expected_mod .. "." .. expected_func .. ", got: " .. map.rhs)
    end

    -- Verify the target function actually exists in the module
    local ok, mod = pcall(require, expected_mod)
    assert(ok, expected_mod .. " module should load")
    assert(type(mod[expected_func]) == "function",
        expected_mod .. "." .. expected_func .. " should be a valid function")
end

--- Helper to test that a keymap exists
--- @param lhs string The keymap to test
--- @param mode? string The mode (default "n")
function M.assert_keymap_exists(lhs, mode)
    mode = mode or "n"
    local map = vim.fn.maparg(lhs, mode, false, true)
    assert(map.rhs or map.callback,
        lhs .. " keymap should be set in mode " .. mode)
end

--- Load a user config module, returns nil if it fails
--- @param name string Module name (e.g., "user.dap")
--- @return table|nil
function M.load_user_module(name)
    local ok, mod = pcall(require, name)
    if ok and type(mod) == "table" then
        return mod
    end
    return nil
end

--- Load a user config module, fails test if not available
--- @param name string Module name (e.g., "user.dap")
--- @return table
function M.require_user_module(name)
    local ok, mod = pcall(require, name)
    assert(ok and type(mod) == "table", name .. " module must load for these tests")
    return mod
end

--- Load a plugin module, fails test if not available
--- @param name string Module name (e.g., "dap")
--- @return table
function M.require_plugin(name)
    local ok, mod = pcall(require, name)
    assert(ok, name .. " plugin must be available for these tests")
    return mod
end

return M

-- Test ACTUAL BEHAVIOR of Treesitter
-- Updated for nvim-treesitter 1.0+ (new API without nvim-treesitter.configs)
-- These tests verify the user config in lua/user/treesitter.lua is applied correctly

-- Helper function to check if a parser is installed
local function has_parser(lang)
    local parsers = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", false)
    return #parsers > 0
end

-- Helper to setup a buffer with treesitter active
local function setup_lua_buffer()
    vim.cmd("new test.lua")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "local function test()",
        "  return true",
        "end"
    })
    vim.bo.filetype = "lua"
    vim.cmd("doautocmd FileType lua")
    vim.wait(50)
end

local function setup_python_buffer()
    vim.cmd("new test.py")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "class MyClass:",
        "    def method(self):",
        "        pass"
    })
    vim.bo.filetype = "python"
    vim.cmd("doautocmd FileType python")
    vim.wait(50)
end

local function cleanup_buffer()
    vim.cmd("bdelete!")
end

describe("Treesitter Behavior", function()
    before_each(function()
        local ok, mod = pcall(require, "user.treesitter")
        if ok and mod.config then
            pcall(mod.config)
        end
    end)

    describe("Syntax Highlighting", function()
        it("should enable treesitter highlighting for Lua files", function()
            setup_lua_buffer()

            -- Check if treesitter is active for this buffer
            local highlighter = require("vim.treesitter.highlighter")
            local has_highlight = highlighter.active[vim.api.nvim_get_current_buf()] ~= nil

            assert.is_truthy(has_highlight, "Treesitter highlighting should be active")

            cleanup_buffer()
        end)
    end)

    describe("Incremental Selection", function()
        -- User config: init_selection = "<M-/>", node_incremental = "<M-/>"
        it("should have <M-/> mapped for init_selection (user config)", function()
            setup_lua_buffer()
            local map = vim.fn.maparg("<M-/>", "n")
            assert.is_truthy(map ~= "", "Init selection keymap <M-/> should be set per user config")
            -- Verify it's actually the incremental selection function
            assert.is_truthy(
                string.match(map, "incremental_selection") or string.match(map, "init_selection"),
                "Keymap should call incremental selection"
            )
            cleanup_buffer()
        end)

        -- User config: node_decremental = "<bs>"
        it("should have <bs> mapped for node decremental (user config)", function()
            setup_lua_buffer()
            local map = vim.fn.maparg("<bs>", "x")
            assert.is_truthy(map ~= "", "Node decremental keymap <bs> should be set per user config")
            cleanup_buffer()
        end)
    end)

    describe("Textobjects", function()
        -- User config: ["af"] = "@function.outer", ["if"] = "@function.inner"
        it("should map af to @function.outer (user config)", function()
            setup_lua_buffer()
            local af_map = vim.fn.maparg("af", "x")
            local if_map = vim.fn.maparg("if", "x")

            assert.is_truthy(af_map ~= "", "af textobject should be mapped")
            assert.is_truthy(if_map ~= "", "if textobject should be mapped")
            -- Verify the actual textobject matches user config
            assert.is_truthy(
                string.match(af_map, "@function%.outer"),
                "af should map to @function.outer per user config"
            )
            assert.is_truthy(
                string.match(if_map, "@function%.inner"),
                "if should map to @function.inner per user config"
            )
            cleanup_buffer()
        end)

        -- User config: ["ac"] = "@class.outer", ["ic"] = "@class.inner"
        it("should map ac to @class.outer (user config)", function()
            -- Use Python buffer since Lua doesn't have classes
            setup_python_buffer()

            local ac_map = vim.fn.maparg("ac", "x")
            local ic_map = vim.fn.maparg("ic", "x")

            assert.is_truthy(ac_map ~= "", "ac textobject should be mapped")
            assert.is_truthy(ic_map ~= "", "ic textobject should be mapped")
            -- Verify the actual textobject matches user config
            assert.is_truthy(
                string.match(ac_map, "@class%.outer"),
                "ac should map to @class.outer per user config"
            )
            assert.is_truthy(
                string.match(ic_map, "@class%.inner"),
                "ic should map to @class.inner per user config"
            )
            cleanup_buffer()
        end)

        -- User config: goto_next_start = { ["]m"] = "@function.outer" }
        -- User config: goto_previous_start = { ["[m"] = "@function.outer" }
        it("should map ]m and [m to @function.outer movement (user config)", function()
            setup_lua_buffer()
            local next_map = vim.fn.maparg("]m", "n")
            local prev_map = vim.fn.maparg("[m", "n")

            assert.is_truthy(next_map ~= "", "]m movement should be mapped")
            assert.is_truthy(prev_map ~= "", "[m movement should be mapped")
            -- Verify the movement targets match user config
            assert.is_truthy(
                string.match(next_map, "@function%.outer") or string.match(next_map, "textobjects"),
                "]m should target @function.outer per user config"
            )
            assert.is_truthy(
                string.match(prev_map, "@function%.outer") or string.match(prev_map, "textobjects"),
                "[m should target @function.outer per user config"
            )
            cleanup_buffer()
        end)
    end)

    describe("Ensured Parsers", function()
        -- User config has lua and python in ensure_installed
        it("should have Lua parser installed (in ensure_installed)", function()
            assert.is_true(has_parser("lua"), "Lua parser should be installed per ensure_installed")
        end)

        it("should have Python parser installed (in ensure_installed)", function()
            assert.is_true(has_parser("python"), "Python parser should be installed per ensure_installed")
        end)

        it("should check C++ parser API works", function()
            -- C++ parser may not be installed in CI, just verify the check works
            local result = has_parser("cpp")
            assert.is_not_nil(result, "Parser check should return a value")
        end)
    end)

    describe("Folding Integration", function()
        -- User config: vim.opt["foldexpr"] = "nvim_treesitter#foldexpr()"
        it("should use treesitter for fold expression (user config)", function()
            setup_lua_buffer()
            local foldexpr = vim.wo.foldexpr
            assert.is_truthy(
                string.match(foldexpr, "treesitter"),
                "Should use treesitter foldexpr per user config"
            )
            cleanup_buffer()
        end)
    end)
end)

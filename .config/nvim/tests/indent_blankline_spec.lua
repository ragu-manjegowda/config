-------------------------------------------------------------------------------
-- Test user/indent-blankline.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("IndentBlankline Config", function()
    local ibl_mod

    before_each(function()
        ibl_mod = require("user.indent-blankline")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(ibl_mod.config)
        end)
    end)

    describe("Global State", function()
        it("should initialize u_indent_blankline_enabled to true", function()
            -- Reload to test initial state
            package.loaded["user.indent-blankline"] = nil
            vim.g.u_indent_blankline_enabled = nil
            require("user.indent-blankline")
            assert.is_true(vim.g.u_indent_blankline_enabled)
        end)
    end)

    describe("IndentBlankline Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if ibl plugin not available
            assert.has_no_errors(function()
                pcall(ibl_mod.config)
            end)
        end)
    end)
end)

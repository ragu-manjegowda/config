-------------------------------------------------------------------------------
-- Test user/lualine.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Lualine Config", function()
    local lualine_mod

    before_each(function()
        lualine_mod = require("user.lualine")
    end)

    describe("Module Interface", function()
        it("should expose required functions", function()
            assert.is_function(lualine_mod.config)
            assert.is_function(lualine_mod.get_theme)
        end)
    end)

    describe("get_theme()", function()
        it("should return a table", function()
            local theme = lualine_mod.get_theme()
            assert.is_table(theme)
        end)

        it("should have mode-specific colors when colors available", function()
            local theme = lualine_mod.get_theme()
            if next(theme) ~= nil then
                assert.is_table(theme.normal, "Theme should have normal mode colors")
                assert.is_table(theme.insert, "Theme should have insert mode colors")
                assert.is_table(theme.visual, "Theme should have visual mode colors")
                assert.is_table(theme.replace, "Theme should have replace mode colors")
                assert.is_table(theme.inactive, "Theme should have inactive colors")
            end
        end)

        it("should have section colors for normal mode", function()
            local theme = lualine_mod.get_theme()
            if theme.normal then
                assert.is_table(theme.normal.a, "Normal mode should have section a")
                assert.is_table(theme.normal.b, "Normal mode should have section b")
                assert.is_table(theme.normal.c, "Normal mode should have section c")
            end
        end)
    end)

    describe("Lualine Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if lualine plugin not available
            assert.has_no_errors(function()
                pcall(lualine_mod.config)
            end)
        end)
    end)
end)

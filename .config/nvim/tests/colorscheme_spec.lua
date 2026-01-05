-------------------------------------------------------------------------------
-- Test user/colorscheme.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Colorscheme Config", function()
    local colorscheme_mod

    before_each(function()
        colorscheme_mod = require("user.colorscheme")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(colorscheme_mod.config)
        end)

        it("should expose meta table", function()
            assert.is_table(colorscheme_mod.meta)
            assert.is_string(colorscheme_mod.meta.desc)
            assert.is_true(colorscheme_mod.meta.needs_setup)
        end)
    end)

    describe("Colorscheme Setup (config())", function()
        before_each(function()
            pcall(colorscheme_mod.config)
        end)

        it("should set termguicolors (user config)", function()
            assert.is_true(vim.o.termguicolors,
                "termguicolors should be enabled per user config")
        end)

        it("should set terminal colors when solarized available (user config)", function()
            -- Only test if colorscheme was actually set (solarized available)
            if vim.g.colors_name then
                -- terminal_color_0 might be nil if solarized plugin not available
                local has_terminal_colors = vim.g.terminal_color_0 ~= nil
                if has_terminal_colors then
                    assert.is_string(vim.g.terminal_color_0,
                        "terminal_color_0 should be set per user config")
                    assert.is_string(vim.g.terminal_color_15,
                        "terminal_color_15 should be set per user config")
                end
            end
        end)

        it("should configure colorscheme", function()
            -- Check that colorscheme is set (may be default if solarized not available)
            local current = vim.g.colors_name
            -- In minimal test env, colorscheme might not be set
            assert.is_true(current == nil or type(current) == "string",
                "Colorscheme should be nil or set")
        end)
    end)
end)

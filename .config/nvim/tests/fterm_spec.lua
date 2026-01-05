-------------------------------------------------------------------------------
-- Test user/fterm.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("FTerm Config", function()
    local fterm_mod

    before_each(function()
        h.require_plugin("FTerm")
        fterm_mod = h.require_user_module("user.fterm")
    end)

    describe("Module Interface", function()
        it("should expose required functions", function()
            assert.is_function(fterm_mod.config)
            assert.is_function(fterm_mod.__fterm_zsh)
            assert.is_function(fterm_mod.terminal_send)
        end)
    end)

    describe("FTerm Keymaps (config())", function()
        before_each(function()
            fterm_mod.config()
        end)

        it("<leader>ts calls user.fterm.__fterm_zsh", function()
            h.assert_keymap_calls("<leader>ts", "user.fterm", "__fterm_zsh", "n")
        end)

        it("<leader>ss calls user.fterm.terminal_send", function()
            h.assert_keymap_exists("<leader>ss", "n")
            local map = vim.fn.maparg("<leader>ss", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "user%.fterm"))
            assert.is_truthy(string.match(map.rhs, "terminal_send"))
        end)
    end)

    describe("FTerm Setup (config())", function()
        it("should configure fterm without error", function()
            assert.has_no_errors(function()
                fterm_mod.config()
            end)
        end)
    end)
end)

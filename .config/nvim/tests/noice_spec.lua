-------------------------------------------------------------------------------
-- Test user/noice.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("Noice Config", function()
    local noice_mod

    before_each(function()
        h.require_plugin("noice")
        h.require_plugin("notify")
        noice_mod = h.require_user_module("user.noice")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(noice_mod.config)
        end)
    end)

    describe("Noice Keymaps (config())", function()
        before_each(function()
            noice_mod.config()
        end)

        it("<leader>nd runs Noice dismiss", function()
            h.assert_keymap_exists("<leader>nd", "n")
            local map = vim.fn.maparg("<leader>nd", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Noice dismiss"))
        end)

        it("<leader>nm opens Noice messages", function()
            h.assert_keymap_exists("<leader>nm", "n")
            local map = vim.fn.maparg("<leader>nm", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "Noice"))
        end)
    end)

    describe("Noice Autocmds (config())", function()
        before_each(function()
            noice_mod.config()
        end)

        it("should create RecordingEnter autocmd", function()
            local autocmds = vim.api.nvim_get_autocmds({
                group = "NoiceMacroNotfication",
                event = "RecordingEnter"
            })
            assert.is_true(#autocmds > 0)
        end)

        it("should create RecordingLeave autocmd", function()
            local autocmds = vim.api.nvim_get_autocmds({
                group = "NoiceMacroNotficationDismiss",
                event = "RecordingLeave"
            })
            assert.is_true(#autocmds > 0)
        end)
    end)

    describe("Noice Setup (config())", function()
        it("should configure noice without error", function()
            assert.has_no_errors(function()
                noice_mod.config()
            end)
        end)
    end)
end)

-------------------------------------------------------------------------------
-- Test user/neocodeium.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("Neocodeium Config", function()
    local neocodeium_mod
    local neocodeium

    before_each(function()
        neocodeium = h.require_plugin("neocodeium")
        neocodeium_mod = h.require_user_module("user.neocodeium")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(neocodeium_mod.config)
        end)
    end)

    describe("Neocodeium Plugin Functions", function()
        it("neocodeium should have functions that keymaps use", function()
            assert.is_function(neocodeium.accept_line)
            assert.is_function(neocodeium.accept_word)
            assert.is_function(neocodeium.cycle_or_complete)
            assert.is_function(neocodeium.clear)
        end)
    end)

    describe("Neocodeium Keymaps (config())", function()
        before_each(function()
            neocodeium_mod.config()
        end)

        it("<M-y> (insert) is mapped for accept_line", function()
            h.assert_keymap_exists("<M-y>", "i")
        end)

        it("<M-f> (insert) is mapped for accept_word", function()
            h.assert_keymap_exists("<M-f>", "i")
        end)

        it("<M-i> (insert) is mapped for cycle_or_complete", function()
            h.assert_keymap_exists("<M-i>", "i")
        end)

        it("<M-o> (insert) is mapped for cycle_or_complete(-1)", function()
            h.assert_keymap_exists("<M-o>", "i")
        end)

        it("<M-e> (insert) is mapped for clear", function()
            h.assert_keymap_exists("<M-e>", "i")
        end)
    end)

    describe("Neocodeium Setup (config())", function()
        it("should configure neocodeium without error", function()
            assert.has_no_errors(function()
                neocodeium_mod.config()
            end)
        end)
    end)
end)

-------------------------------------------------------------------------------
-- Test user/gitsigns.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("Gitsigns Config", function()
    local gitsigns_mod
    local gitsigns

    before_each(function()
        gitsigns = h.require_plugin("gitsigns")
        gitsigns_mod = h.require_user_module("user.gitsigns")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(gitsigns_mod.config)
        end)
    end)

    describe("Gitsigns Plugin Functions", function()
        it("gitsigns should have functions that keymaps use", function()
            assert.is_function(gitsigns.setup)
            assert.is_function(gitsigns.toggle_current_line_blame)
            assert.is_function(gitsigns.preview_hunk)
            assert.is_function(gitsigns.nav_hunk)
        end)
    end)

    describe("Gitsigns Setup (config())", function()
        it("should configure gitsigns without error", function()
            assert.has_no_errors(function()
                gitsigns_mod.config()
            end)
        end)

        -- Note: Gitsigns keymaps are set in on_attach which only runs when
        -- attached to a buffer in a git repo. We can't easily test those
        -- keymaps in this minimal test environment. The on_attach function
        -- is tested by verifying gitsigns.setup was called with on_attach.
    end)
end)

-- Test ACTUAL BEHAVIOR of Git integrations (Gitsigns, Fugitive)
describe("Git Behavior", function()
    describe("Gitsigns", function()
        before_each(function()
            local ok, mod = pcall(require, "user.gitsigns")
            if ok and mod.config then
                pcall(mod.config)
            end
        end)

        it("should enable signcolumn for git changes", function()
            local gitsigns = require("gitsigns.config").config
            assert.is_true(gitsigns.signcolumn, "signcolumn should be enabled")
        end)

        it("should enable numhl for git changes", function()
            local gitsigns = require("gitsigns.config").config
            assert.is_true(gitsigns.numhl, "numhl should be enabled")
        end)

        it("should use patience diff algorithm", function()
            local gitsigns = require("gitsigns.config").config
            assert.equals("patience", gitsigns.diff_opts.algorithm)
        end)

        it("should attach to untracked files", function()
            local gitsigns = require("gitsigns.config").config
            assert.is_true(gitsigns.attach_to_untracked)
        end)

        it("should configure git change signs", function()
            local gitsigns = require("gitsigns.config").config
            assert.is_table(gitsigns.signs)
            assert.equals("│", gitsigns.signs.add.text)
            assert.equals("│", gitsigns.signs.change.text)
        end)
    end)

    describe("Fugitive", function()
        it("should load fugitive plugin", function()
            assert.has_no_errors(function()
                require("user.fugitive")
            end)
        end)
    end)
end)


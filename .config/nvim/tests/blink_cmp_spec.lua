-------------------------------------------------------------------------------
-- Test user/blink-cmp.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("BlinkCmp Config", function()
    local blinkcmp_mod

    before_each(function()
        blinkcmp_mod = require("user.blink-cmp")
    end)

    describe("Module Interface", function()
        it("should expose opts function", function()
            assert.is_function(blinkcmp_mod.opts)
        end)
    end)

    describe("opts()", function()
        local opts

        before_each(function()
            opts = blinkcmp_mod.opts()
        end)

        it("should return a table", function()
            assert.is_table(opts)
        end)

        it("should use default keymap preset (user config)", function()
            assert.is_table(opts.keymap)
            assert.equals("default", opts.keymap.preset,
                "keymap preset should be 'default' per user config")
        end)

        it("should configure <M-k> for scroll_documentation_up (user config)", function()
            assert.is_table(opts.keymap["<M-k>"],
                "<M-k> should be configured per user config")
        end)

        it("should configure <M-j> for scroll_documentation_down (user config)", function()
            assert.is_table(opts.keymap["<M-j>"],
                "<M-j> should be configured per user config")
        end)

        it("should disable auto_brackets (user config)", function()
            assert.is_table(opts.completion.accept.auto_brackets)
            assert.is_false(opts.completion.accept.auto_brackets.enabled,
                "auto_brackets should be disabled per user config")
        end)

        it("should enable auto_show for documentation (user config)", function()
            assert.is_true(opts.completion.documentation.auto_show,
                "documentation.auto_show should be enabled per user config")
        end)

        it("should set documentation auto_show_delay_ms to 500 (user config)", function()
            assert.equals(500, opts.completion.documentation.auto_show_delay_ms,
                "auto_show_delay_ms should be 500 per user config")
        end)

        it("should use rounded border for documentation (user config)", function()
            assert.equals("rounded", opts.completion.documentation.window.border,
                "documentation window border should be rounded per user config")
        end)

        it("should set keyword range to full (user config)", function()
            assert.equals("full", opts.completion.keyword.range,
                "keyword.range should be 'full' per user config")
        end)

        it("should disable preselect in list selection (user config)", function()
            assert.is_false(opts.completion.list.selection.preselect,
                "list.selection.preselect should be false per user config")
        end)

        it("should enable auto_insert in list selection (user config)", function()
            assert.is_true(opts.completion.list.selection.auto_insert,
                "list.selection.auto_insert should be true per user config")
        end)

        it("should use rounded border for menu (user config)", function()
            assert.equals("rounded", opts.completion.menu.border,
                "menu border should be rounded per user config")
        end)

        it("should configure default sources (user config)", function()
            assert.is_table(opts.sources.default)
            local expected = { "lsp", "path", "snippets", "buffer" }
            for _, src in ipairs(expected) do
                assert.is_truthy(vim.tbl_contains(opts.sources.default, src),
                    src .. " should be in default sources per user config")
            end
        end)

        it("should disable signature (user config)", function()
            assert.is_false(opts.signature.enabled,
                "signature should be disabled per user config")
        end)
    end)
end)

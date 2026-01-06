-------------------------------------------------------------------------------
-- Test user/opencode.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end

describe("Opencode Config", function()
    local opencode_mod

    before_each(function()
        opencode_mod = require("user.opencode")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(opencode_mod.config)
        end)

        it("should expose opts function", function()
            assert.is_function(opencode_mod.opts)
        end)

        it("should expose keymap table", function()
            assert.is_table(opencode_mod.keymap)
        end)

        it("should expose ui table", function()
            assert.is_table(opencode_mod.ui)
        end)

        it("should expose toggle_in_new_tab function", function()
            assert.is_function(opencode_mod.toggle_in_new_tab)
        end)

        it("should expose patch_session_for_non_git function", function()
            assert.is_function(opencode_mod.patch_session_for_non_git)
        end)
    end)

    describe("opts()", function()
        local opts

        before_each(function()
            opts = opencode_mod.opts()
        end)

        it("should return a table", function()
            assert.is_table(opts)
        end)

        it("should contain keymap configuration", function()
            assert.is_table(opts.keymap)
        end)

        it("should contain ui configuration", function()
            assert.is_table(opts.ui)
        end)
    end)

    describe("keymap configuration", function()
        local keymap

        before_each(function()
            keymap = opencode_mod.keymap
        end)

        it("should have input_window keymaps", function()
            assert.is_table(keymap.input_window)
        end)

        it("should not override editor keymaps (use default <leader>og)", function()
            assert.is_nil(keymap.editor,
                "editor keymaps should be nil to use default toggle behavior")
        end)

        describe("input_window keymaps", function()
            local input_keymaps

            before_each(function()
                input_keymaps = keymap.input_window
            end)

            it("<cr> should submit prompt in normal mode only", function()
                local cr_config = input_keymaps["<cr>"]
                assert.is_table(cr_config)
                assert.equals("submit_input_prompt", cr_config[1])
                assert.equals("n", cr_config.mode,
                    "<cr> should be normal mode only (not insert, since <C-m> = <CR> in terminals)")
            end)

            it("<C-s> should submit prompt in insert mode", function()
                local cs_config = input_keymaps["<C-s>"]
                assert.is_table(cs_config)
                assert.equals("submit_input_prompt", cs_config[1])
                assert.equals("i", cs_config.mode,
                    "<C-s> should be set to insert mode for submission")
            end)

            it("<esc> should be disabled", function()
                local esc_config = input_keymaps["<esc>"]
                assert.is_false(esc_config,
                    "<esc> should be disabled (set to false)")
            end)

            it("~ should mention file in normal mode", function()
                local tilde_config = input_keymaps["~"]
                assert.is_table(tilde_config)
                assert.equals("mention_file", tilde_config[1])
                assert.equals("n", tilde_config.mode)
            end)

            it("@ should insert mention in insert mode", function()
                local at_config = input_keymaps["@"]
                assert.is_table(at_config)
                assert.equals("mention", at_config[1])
                assert.equals("i", at_config.mode)
            end)

            it("/ should trigger slash commands in insert mode", function()
                local slash_config = input_keymaps["/"]
                assert.is_table(slash_config)
                assert.equals("slash_commands", slash_config[1])
                assert.equals("i", slash_config.mode)
            end)

            it("# should show context items in insert mode", function()
                local hash_config = input_keymaps["#"]
                assert.is_table(hash_config)
                assert.equals("context_items", hash_config[1])
                assert.equals("i", hash_config.mode)
            end)

            -- Verify mode is string not table to avoid vim.tbl_deep_extend issues
            it("all modes should be strings not tables", function()
                for key, config in pairs(input_keymaps) do
                    if type(config) == "table" and config.mode then
                        assert.is_string(config.mode,
                            key .. " mode should be string, not table, to avoid deep merge issues")
                    end
                end
            end)
        end)
    end)

    describe("ui configuration", function()
        local ui

        before_each(function()
            ui = opencode_mod.ui
        end)

        it("should set position to right", function()
            assert.equals("right", ui.position,
                "position should be 'right' to open in right split")
        end)

        it("should have output configuration", function()
            assert.is_table(ui.output)
        end)

        it("should enable auto_scroll for output", function()
            assert.is_true(ui.output.auto_scroll,
                "auto_scroll should be enabled for output")
        end)

        it("should have rendering configuration for performance", function()
            assert.is_table(ui.output.rendering)
            assert.equals(500, ui.output.rendering.markdown_debounce_ms)
            assert.equals(100, ui.output.rendering.event_throttle_ms)
            assert.is_true(ui.output.rendering.event_collapsing)
        end)
    end)
end)

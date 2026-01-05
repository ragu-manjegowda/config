-------------------------------------------------------------------------------
-- Test user/telescope.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local h = require("tests.test_helper")

describe("Telescope Config", function()
    local telescope_mod
    local telescope

    before_each(function()
        telescope = h.require_plugin("telescope")
        h.require_plugin("telescope.builtin")
        telescope_mod = h.require_user_module("user.telescope")
    end)

    describe("Module Interface", function()
        it("should expose required functions", function()
            assert.is_function(telescope_mod.before)
            assert.is_function(telescope_mod.config)
            assert.is_function(telescope_mod.grep)
            assert.is_function(telescope_mod.grep_folder)
            assert.is_function(telescope_mod.grep_word)
            assert.is_function(telescope_mod.grep_word_exact)
            assert.is_function(telescope_mod.live_grep)
            assert.is_function(telescope_mod.live_grep_current_buffer_folder)
            assert.is_function(telescope_mod.find_files)
            assert.is_function(telescope_mod.current_buffer_fuzzy_find)
            assert.is_function(telescope_mod.getVisualSelection)
        end)
    end)

    describe("Telescope Builtin Functions", function()
        it("telescope.builtin should have functions that keymaps use", function()
            local builtin = require("telescope.builtin")
            assert.is_function(builtin.buffers)
            assert.is_function(builtin.command_history)
            assert.is_function(builtin.find_files)
            assert.is_function(builtin.grep_string)
            assert.is_function(builtin.help_tags)
            assert.is_function(builtin.jumplist)
            assert.is_function(builtin.keymaps)
            assert.is_function(builtin.man_pages)
            assert.is_function(builtin.quickfix)
            assert.is_function(builtin.registers)
            assert.is_function(builtin.spell_suggest)
            assert.is_function(builtin.treesitter)
            assert.is_function(builtin.current_buffer_fuzzy_find)
            assert.is_function(builtin.lsp_incoming_calls)
            assert.is_function(builtin.lsp_outgoing_calls)
            assert.is_function(builtin.diagnostics)
            assert.is_function(builtin.git_commits)
            assert.is_function(builtin.git_bcommits)
        end)
    end)

    describe("Telescope Keymaps (before())", function()
        before_each(function()
            telescope_mod.before()
        end)

        -- Buffer/Project keymaps
        it("<leader>bs calls user.telescope.current_buffer_fuzzy_find", function()
            h.assert_keymap_calls("<leader>bs", "user.telescope", "current_buffer_fuzzy_find", "n")
        end)

        it("<leader>fg calls user.telescope.live_grep", function()
            h.assert_keymap_calls("<leader>fg", "user.telescope", "live_grep", "n")
        end)

        it("<leader>fgp calls user.telescope.live_grep_current_buffer_folder", function()
            h.assert_keymap_calls("<leader>fgp", "user.telescope", "live_grep_current_buffer_folder", "n")
        end)

        it("<leader>pb calls telescope.builtin.buffers", function()
            h.assert_keymap_calls("<leader>pb", "telescope.builtin", "buffers", "n")
        end)

        it("<leader>pc calls telescope.builtin.command_history", function()
            h.assert_keymap_calls("<leader>pc", "telescope.builtin", "command_history", "n")
        end)

        it("<leader>pf calls user.telescope.find_files", function()
            h.assert_keymap_calls("<leader>pf", "user.telescope", "find_files", "n")
        end)

        it("<leader>ph calls telescope.builtin.help_tags", function()
            h.assert_keymap_calls("<leader>ph", "telescope.builtin", "help_tags", "n")
        end)

        it("<leader>pj calls telescope.builtin.jumplist", function()
            h.assert_keymap_calls("<leader>pj", "telescope.builtin", "jumplist", "n")
        end)

        it("<leader>pk calls telescope.builtin.keymaps", function()
            h.assert_keymap_calls("<leader>pk", "telescope.builtin", "keymaps", "n")
        end)

        it("<leader>pm calls telescope.builtin.man_pages", function()
            h.assert_keymap_calls("<leader>pm", "telescope.builtin", "man_pages", "n")
        end)

        it("<leader>pq calls telescope.builtin.quickfix", function()
            h.assert_keymap_calls("<leader>pq", "telescope.builtin", "quickfix", "n")
        end)

        it("<leader>pr calls telescope.builtin.registers", function()
            h.assert_keymap_calls("<leader>pr", "telescope.builtin", "registers", "n")
        end)

        it("<leader>ps calls user.telescope.grep", function()
            h.assert_keymap_calls("<leader>ps", "user.telescope", "grep", "n")
        end)

        it("<leader>psf calls user.telescope.grep_folder", function()
            h.assert_keymap_calls("<leader>psf", "user.telescope", "grep_folder", "n")
        end)

        it("<leader>pt calls telescope.builtin.treesitter", function()
            h.assert_keymap_calls("<leader>pt", "telescope.builtin", "treesitter", "n")
        end)

        it("<leader>pw calls user.telescope.grep_word", function()
            h.assert_keymap_calls("<leader>pw", "user.telescope", "grep_word", "n")
        end)

        it("<leader>pW calls user.telescope.grep_word_exact", function()
            h.assert_keymap_calls("<leader>pW", "user.telescope", "grep_word_exact", "n")
        end)

        -- LSP keymaps
        it("<leader>lic calls telescope.builtin.lsp_incoming_calls", function()
            h.assert_keymap_calls("<leader>lic", "telescope.builtin", "lsp_incoming_calls", "n")
        end)

        it("<leader>loc calls telescope.builtin.lsp_outgoing_calls", function()
            h.assert_keymap_calls("<leader>loc", "telescope.builtin", "lsp_outgoing_calls", "n")
        end)

        it("<leader>oe calls telescope.builtin.diagnostics", function()
            h.assert_keymap_calls("<leader>oe", "telescope.builtin", "diagnostics", "n")
        end)

        -- Git keymaps
        it("<leader>glogt calls telescope.builtin.git_commits", function()
            h.assert_keymap_calls("<leader>glogt", "telescope.builtin", "git_commits", "n")
        end)

        it("<leader>glogft calls telescope.builtin.git_bcommits", function()
            h.assert_keymap_calls("<leader>glogft", "telescope.builtin", "git_bcommits", "n")
        end)

        -- Spell suggest
        it("z= calls telescope.builtin.spell_suggest", function()
            h.assert_keymap_calls("z=", "telescope.builtin", "spell_suggest", "n")
        end)

        -- DAP keymaps
        it("<leader>dlb calls telescope.extensions.dap.list_breakpoints", function()
            h.assert_keymap_exists("<leader>dlb", "n")
            local map = vim.fn.maparg("<leader>dlb", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "telescope"))
            assert.is_truthy(string.match(map.rhs, "dap"))
            assert.is_truthy(string.match(map.rhs, "list_breakpoints"))
        end)

        it("<leader>dbt calls telescope.extensions.dap.frames", function()
            h.assert_keymap_exists("<leader>dbt", "n")
            local map = vim.fn.maparg("<leader>dbt", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "telescope"))
            assert.is_truthy(string.match(map.rhs, "dap"))
            assert.is_truthy(string.match(map.rhs, "frames"))
        end)

        -- Undo tree
        it("<leader>ut calls telescope.extensions.undo.undo", function()
            h.assert_keymap_exists("<leader>ut", "n")
            local map = vim.fn.maparg("<leader>ut", "n", false, true)
            assert.is_truthy(string.match(map.rhs, "telescope"))
            assert.is_truthy(string.match(map.rhs, "undo"))
        end)
    end)

    describe("Telescope Setup (config())", function()
        it("should configure telescope without error", function()
            assert.has_no_errors(function()
                telescope_mod.config()
            end)
        end)

        it("should load required extensions", function()
            telescope_mod.config()
            assert.has_no_errors(function()
                telescope.load_extension("fzf")
                telescope.load_extension("undo")
                telescope.load_extension("dap")
                telescope.load_extension("live_grep_args")
            end)
        end)
    end)
end)

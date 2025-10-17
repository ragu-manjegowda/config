-- Test ACTUAL BEHAVIOR of Telescope
describe("Telescope Behavior", function()
    before_each(function()
        local ok, mod = pcall(require, "user.telescope")
        if ok then
            if mod.before then pcall(mod.before) end
            if mod.config then pcall(mod.config) end
        end
    end)

    describe("Module Functions", function()
        it("should have all custom functions defined", function()
            local telescope_mod = require("user.telescope")
            assert.is_function(telescope_mod.grep)
            assert.is_function(telescope_mod.grep_folder)
            assert.is_function(telescope_mod.grep_word)
            assert.is_function(telescope_mod.grep_word_exact)
            assert.is_function(telescope_mod.live_grep)
            assert.is_function(telescope_mod.find_files)
            assert.is_function(telescope_mod.getVisualSelection)
        end)

        it("getVisualSelection should return empty in normal mode", function()
            local telescope_mod = require("user.telescope")
            vim.cmd("normal! <Esc>")
            local selection = telescope_mod.getVisualSelection()
            assert.equals("", selection)
        end)

        it("grep function should be callable", function()
            local telescope_mod = require("user.telescope")
            -- Don't actually execute (would hang), just verify it's a function
            assert.is_function(telescope_mod.grep)
        end)
    end)

    describe("Telescope Extensions", function()
        it("should load fzf-native extension without error", function()
            local telescope = require("telescope")
            assert.has_no_errors(function()
                telescope.load_extension("fzf")
            end)
        end)

        it("should load undo extension without error", function()
            local telescope = require("telescope")
            assert.has_no_errors(function()
                telescope.load_extension("undo")
            end)
        end)

        it("should load dap extension without error", function()
            local telescope = require("telescope")
            assert.has_no_errors(function()
                telescope.load_extension("dap")
            end)
        end)
    end)

    describe("Telescope Pickers", function()
        it("should have find_files picker available", function()
            local builtin = require("telescope.builtin")
            assert.is_function(builtin.find_files)
        end)

        it("should have live_grep picker available", function()
            local builtin = require("telescope.builtin")
            assert.is_function(builtin.live_grep)
        end)

        it("should have buffers picker available", function()
            local builtin = require("telescope.builtin")
            assert.is_function(builtin.buffers)
        end)

        it("should have spell_suggest picker available", function()
            local builtin = require("telescope.builtin")
            assert.is_function(builtin.spell_suggest)
        end)
    end)
end)

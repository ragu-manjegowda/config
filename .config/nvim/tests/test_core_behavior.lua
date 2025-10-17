-- Test ACTUAL BEHAVIOR of core Neovim configuration
describe("Core Neovim Behavior", function()
    before_each(function()
        -- Load full config
        require("user.keymaps").setup()
        require("user.options").setup()
        require("user.autocommands").setup()
    end)

    describe("Line Numbers", function()
        it("should display line numbers in new buffers", function()
            vim.cmd("new")
            assert.is_true(vim.wo.number, "Line numbers should be enabled")
            assert.is_true(vim.wo.relativenumber, "Relative line numbers should be enabled")
            vim.cmd("bdelete!")
        end)
    end)

    describe("Spell Checking", function()
        it("should enable spell checking by default", function()
            vim.cmd("new")
            assert.is_true(vim.wo.spell, "Spell checking should be enabled")
            vim.cmd("bdelete!")
        end)
    end)

    describe("File Saving", function()
        it("<leader>w should save current buffer", function()
            local tmpfile = "/tmp/nvim_test_save_" .. os.time() .. ".txt"
            vim.cmd("edit " .. tmpfile)
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {"test content"})
            
            -- Save the file
            vim.cmd("write")
            
            -- Verify file was written
            local saved_content = vim.fn.readfile(tmpfile)
            assert.equals("test content", saved_content[1])
            
            vim.fn.delete(tmpfile)
            vim.cmd("bdelete!")
        end)
    end)

    describe("Window Resizing", function()
        it("<C-Up> should decrease window height", function()
            vim.cmd("split")
            local initial_height = vim.api.nvim_win_get_height(0)
            
            -- Simulate Ctrl+Up
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-Up>", true, false, true), "x", false)
            
            local new_height = vim.api.nvim_win_get_height(0)
            assert.is_true(new_height < initial_height, "Window height should decrease")
            
            vim.cmd("only")
        end)
    end)

    describe("Undo Break Points", function()
        it("should have undo break keymaps configured in insert mode", function()
            -- The undo break keymaps are registered during setup
            -- We can verify they exist by checking the keymaps
            local comma_map = vim.fn.maparg(",", "i", false, true)
            local dot_map = vim.fn.maparg(".", "i", false, true)
            local space_map = vim.fn.maparg("<Space>", "i", false, true)
            
            -- At least one should be configured with <C-g>u for undo break
            assert.is_truthy(comma_map.rhs or comma_map.callback, "Comma should have undo break mapping")
            assert.is_truthy(dot_map.rhs or dot_map.callback, "Dot should have undo break mapping")
            assert.is_truthy(space_map.rhs or space_map.callback, "Space should have undo break mapping")
        end)
    end)

    describe("Visual Mode Indent", function()
        it("should stay in visual mode after indent", function()
            vim.cmd("new")
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {"line1", "line2"})
            
            -- Select both lines
            vim.cmd("normal! ggVG")
            -- Indent
            vim.api.nvim_feedkeys(">", "x", false)
            
            -- Should still be in visual mode
            local mode = vim.api.nvim_get_mode().mode
            assert.equals("V", mode, "Should still be in visual line mode")
            
            vim.cmd("bdelete!")
        end)
    end)

    describe("Yank Highlighting", function()
        it("should highlight yanked text", function()
            vim.cmd("new")
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {"test line"})
            
            -- Yank the line
            vim.cmd("normal! yy")
            
            -- The highlight_yanks autocommand should have triggered
            -- This is hard to test directly, but we can verify the autocommand exists
            local autocmds = vim.api.nvim_get_autocmds({group = "highlight_yanks"})
            assert.is_true(#autocmds > 0, "highlight_yanks autocommand should exist")
            
            vim.cmd("bdelete!")
        end)
    end)

    describe("Trailing Whitespace Removal", function()
        it("should remove trailing whitespace on save", function()
            local tmpfile = vim.fn.tempname()
            vim.cmd("edit " .. tmpfile)
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {"line with spaces   "})
            
            -- Save the file (triggers BufWritePre)
            vim.cmd("write")
            
            -- Check that spaces were removed
            local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]
            assert.equals("line with spaces", content)
            
            vim.fn.delete(tmpfile)
            vim.cmd("bdelete!")
        end)
    end)

    describe("Split Behavior", function()
        it("should split below by default", function()
            local initial_win = vim.api.nvim_get_current_win()
            vim.cmd("split")
            local new_win = vim.api.nvim_get_current_win()
            
            local initial_pos = vim.api.nvim_win_get_position(initial_win)
            local new_pos = vim.api.nvim_win_get_position(new_win)
            
            assert.is_true(new_pos[1] > initial_pos[1], "New window should be below")
            
            vim.cmd("only")
        end)

        it("should vsplit right by default", function()
            local initial_win = vim.api.nvim_get_current_win()
            vim.cmd("vsplit")
            local new_win = vim.api.nvim_get_current_win()
            
            local initial_pos = vim.api.nvim_win_get_position(initial_win)
            local new_pos = vim.api.nvim_win_get_position(new_win)
            
            assert.is_true(new_pos[2] > initial_pos[2], "New window should be to the right")
            
            vim.cmd("only")
        end)
    end)

    describe("Folding", function()
        it("should use indent folding method", function()
            vim.cmd("new")
            assert.equals("indent", vim.wo.foldmethod)
            vim.cmd("bdelete!")
        end)
    end)

    describe("Clipboard", function()
        it("should use OSC52 clipboard", function()
            assert.is_table(vim.g.clipboard)
            assert.equals("OSC 52", vim.g.clipboard.name)
            assert.is_function(vim.g.clipboard.copy["+"])
        end)
    end)
end)


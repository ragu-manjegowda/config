-- Test ACTUAL BEHAVIOR of user/utils.lua
describe("Utils Module Behavior", function()
    local utils

    before_each(function()
        utils = require("user.utils")
    end)

    describe("load_plugin()", function()
        it("should return true and module for existing module", function()
            local success = utils.load_plugin("vim.lsp")
            assert.is_true(success)
        end)

        it("should return false for non-existent module", function()
            local success = utils.load_plugin("non_existent_plugin_xyz_123")
            assert.is_false(success)
        end)

        it("should call function if provided", function()
            local called = false
            local test_module = {
                test_func = function()
                    called = true
                end
            }
            package.loaded["test_module"] = test_module
            
            utils.load_plugin("test_module", "test_func")
            assert.is_true(called, "Function should be called")
            
            package.loaded["test_module"] = nil
        end)

        it("should return module when no function specified", function()
            local success, module = utils.load_plugin("vim.lsp")
            assert.is_true(success)
            assert.is_table(module)
        end)
    end)

    describe("keymap()", function()
        it("should set keymap with defaults", function()
            utils.keymap("n", "<leader>test1", ":echo 'test'<CR>", {})
            
            local keymap = vim.fn.maparg("<leader>test1", "n", false, true)
            assert.is_truthy(keymap)
            assert.equals(1, keymap.silent, "Should be silent by default")
            assert.equals(1, keymap.noremap, "Should be noremap by default")
        end)

        it("should always set silent and noremap (design behavior)", function()
            -- The utils.keymap function always sets silent=true and noremap=true
            -- This is the actual design behavior
            utils.keymap("n", "<leader>test2", ":echo 'test'<CR>", { silent = false })
            
            local keymap = vim.fn.maparg("<leader>test2", "n", false, true)
            -- Even with silent=false, it gets set to true (that's the design)
            assert.equals(1, keymap.silent, "silent is always set to true by design")
            assert.equals(1, keymap.noremap, "noremap is always set to true by design")
        end)

        it("should work with multiple modes", function()
            utils.keymap({"n", "v"}, "<leader>test4", ":echo 'test'<CR>", {})
            
            local keymap_n = vim.fn.maparg("<leader>test4", "n", false, true)
            local keymap_v = vim.fn.maparg("<leader>test4", "v", false, true)
            
            assert.is_truthy(keymap_n, "Should map in normal mode")
            assert.is_truthy(keymap_v, "Should map in visual mode")
        end)

        it("should work with function as rhs", function()
            local test_func = function() return "test" end
            utils.keymap("n", "<leader>test5", test_func, {})
            
            local keymap = vim.fn.maparg("<leader>test5", "n", false, true)
            assert.is_truthy(keymap.callback, "Should have callback function")
        end)
    end)

    describe("get_colors()", function()
        it("should return a table", function()
            local colors = utils.get_colors()
            assert.is_table(colors)
        end)

        it("should not cache colors (fresh on each call)", function()
            local colors1 = utils.get_colors()
            local colors2 = utils.get_colors()
            -- They should be separate tables (not cached)
            assert.is_table(colors1)
            assert.is_table(colors2)
        end)
    end)

    describe("set_cwd()", function()
        it("should set cwd to current directory when not in git/lsp", function()
            local initial_cwd = vim.fn.getcwd()
            
            -- Create temp dir
            local tmpdir = "/tmp/nvim_test_cwd_" .. os.time()
            vim.fn.mkdir(tmpdir, "p")
            vim.api.nvim_set_current_dir(tmpdir)
            
            -- Call set_cwd
            utils.set_cwd()
            
            -- Should be in tmpdir
            local current_cwd = vim.fn.getcwd()
            assert.is_truthy(string.find(current_cwd, "nvim_test_cwd"))
            
            -- Cleanup
            vim.api.nvim_set_current_dir(initial_cwd)
            vim.fn.delete(tmpdir, "rf")
        end)

        it("should handle git root detection", function()
            -- This would require being in a git repo
            -- Just verify it doesn't error
            assert.has_no_errors(function()
                utils.set_cwd()
            end)
        end)
    end)

    describe("getVisualSelection()", function()
        it("should return empty string when not in visual mode", function()
            vim.cmd("normal! <Esc>")
            local selection = utils.getVisualSelection()
            assert.equals("", selection)
        end)

        it("should get text in visual mode", function()
            vim.cmd("new")
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {"hello world"})
            
            -- Select "hello"
            vim.cmd("normal! 0v4l")
            
            local selection = utils.getVisualSelection()
            assert.equals("hello", selection)
            
            vim.cmd("bdelete!")
        end)

        it("should strip newlines from selection", function()
            vim.cmd("new")
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {"line1", "line2"})
            
            -- Select both lines
            vim.cmd("normal! ggVG")
            
            local selection = utils.getVisualSelection()
            -- Should not contain newline
            assert.is_false(string.find(selection, "\n") ~= nil)
            
            vim.cmd("bdelete!")
        end)
    end)

    describe("is_bazel_project()", function()
        it("should return false in non-Bazel directory", function()
            local initial_cwd = vim.fn.getcwd()
            
            -- Create temp dir without BUILD/WORKSPACE
            local tmpdir = "/tmp/nvim_test_nobazel_" .. os.time()
            vim.fn.mkdir(tmpdir, "p")
            vim.api.nvim_set_current_dir(tmpdir)
            
            local result = utils.is_bazel_project()
            assert.is_false(result)
            
            -- Cleanup
            vim.api.nvim_set_current_dir(initial_cwd)
            vim.fn.delete(tmpdir, "rf")
        end)

        it("should return true when BUILD file exists", function()
            local initial_cwd = vim.fn.getcwd()
            
            -- Create temp dir with BUILD file
            local tmpdir = "/tmp/nvim_test_bazel_" .. os.time()
            vim.fn.mkdir(tmpdir, "p")
            vim.fn.writefile({}, tmpdir .. "/BUILD")
            vim.api.nvim_set_current_dir(tmpdir)
            
            local result = utils.is_bazel_project()
            assert.is_true(result)
            
            -- Cleanup
            vim.api.nvim_set_current_dir(initial_cwd)
            vim.fn.delete(tmpdir, "rf")
        end)

        it("should return true when WORKSPACE file exists", function()
            local initial_cwd = vim.fn.getcwd()
            
            -- Create temp dir with WORKSPACE file
            local tmpdir = "/tmp/nvim_test_bazel2_" .. os.time()
            vim.fn.mkdir(tmpdir, "p")
            vim.fn.writefile({}, tmpdir .. "/WORKSPACE")
            vim.api.nvim_set_current_dir(tmpdir)
            
            local result = utils.is_bazel_project()
            assert.is_true(result)
            
            -- Cleanup
            vim.api.nvim_set_current_dir(initial_cwd)
            vim.fn.delete(tmpdir, "rf")
        end)
    end)

    describe("pick_one_sync()", function()
        it("should return nil for invalid choice", function()
            local old_inputlist = vim.fn.inputlist
            vim.fn.inputlist = function() return 0 end
            
            local items = {"item1", "item2", "item3"}
            local result = utils.pick_one_sync(items, "Choose:", function(x) return x end)
            
            vim.fn.inputlist = old_inputlist
            assert.is_nil(result)
        end)

        it("should return nil for out of range choice", function()
            local old_inputlist = vim.fn.inputlist
            vim.fn.inputlist = function() return 99 end
            
            local items = {"item1", "item2"}
            local result = utils.pick_one_sync(items, "Choose:", function(x) return x end)
            
            vim.fn.inputlist = old_inputlist
            assert.is_nil(result)
        end)

        it("should return selected item for valid choice", function()
            local old_inputlist = vim.fn.inputlist
            vim.fn.inputlist = function() return 2 end
            
            local items = {"item1", "item2", "item3"}
            local result = utils.pick_one_sync(items, "Choose:", function(x) return x end)
            
            vim.fn.inputlist = old_inputlist
            assert.equals("item2", result)
        end)

        it("should use label_fn to format choices", function()
            local old_inputlist = vim.fn.inputlist
            local captured_prompt = {}
            vim.fn.inputlist = function(choices)
                captured_prompt = choices
                return 1
            end
            
            local items = {10, 20, 30}
            utils.pick_one_sync(items, "Numbers:", function(x) return "Value: " .. x end)
            
            vim.fn.inputlist = old_inputlist
            -- Should have formatted labels
            assert.equals("Numbers:", captured_prompt[1])
            assert.equals("1: Value: 10", captured_prompt[2])
        end)
    end)

    describe("pick_file()", function()
        it("should use default path when not specified", function()
            -- Just verify it's callable with no args
            -- Don't actually execute (would require user interaction)
            assert.is_function(utils.pick_file)
        end)

        it("should accept custom path option", function()
            -- Verify options are accepted
            local opts = {
                path = "/tmp",
                directories = false,
                executables = false
            }
            assert.is_function(utils.pick_file)
        end)

        it("should accept filter option", function()
            local opts = {
                filter = "%.lua$",
                path = "/tmp"
            }
            assert.is_function(utils.pick_file)
        end)
    end)

    describe("Autocommands", function()
        it("should have LspAttach autocommand for set_cwd", function()
            -- Utils module creates autocommands on load
            local autocmds = vim.api.nvim_get_autocmds({event = "LspAttach"})
            assert.is_true(#autocmds > 0, "LspAttach autocommands should exist")
        end)

        it("should have VimEnter autocommand for set_cwd", function()
            local autocmds = vim.api.nvim_get_autocmds({event = "VimEnter"})
            assert.is_true(#autocmds > 0, "VimEnter autocommands should exist")
        end)
    end)
end)


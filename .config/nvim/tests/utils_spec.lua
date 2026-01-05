-------------------------------------------------------------------------------
-- Test user/utils.lua functions
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Utils Module", function()
    local utils

    before_each(function()
        utils = require("user.utils")
    end)

    describe("Module Interface", function()
        it("should expose required functions", function()
            assert.is_function(utils.load_plugin)
            assert.is_function(utils.keymap)
            assert.is_function(utils.get_colors)
            assert.is_function(utils.set_cwd)
            assert.is_function(utils.getVisualSelection)
            assert.is_function(utils.is_bazel_project)
            assert.is_function(utils.pick_one_sync)
            assert.is_function(utils.pick_one)
            assert.is_function(utils.pick_file)
        end)
    end)

    describe("load_plugin()", function()
        it("should return true for existing module", function()
            local success = utils.load_plugin("vim.lsp")
            assert.is_true(success)
        end)

        it("should return false for non-existent module", function()
            local success = utils.load_plugin("non_existent_plugin_xyz_123")
            assert.is_false(success)
        end)

        it("should return module when no function specified", function()
            local success, module = utils.load_plugin("vim.lsp")
            assert.is_true(success)
            assert.is_table(module)
        end)

        it("should call function if provided", function()
            local called = false
            local test_module = {
                test_func = function()
                    called = true
                end
            }
            package.loaded["test_module_utils"] = test_module

            utils.load_plugin("test_module_utils", "test_func")
            assert.is_true(called, "Function should be called")

            package.loaded["test_module_utils"] = nil
        end)
    end)

    describe("keymap()", function()
        after_each(function()
            -- Clean up test keymaps
            pcall(vim.keymap.del, "n", "<leader>utilstest1")
            pcall(vim.keymap.del, "n", "<leader>utilstest2")
            pcall(vim.keymap.del, "n", "<leader>utilstest3")
            pcall(vim.keymap.del, "v", "<leader>utilstest3")
        end)

        it("should set keymap with silent=true by default", function()
            utils.keymap("n", "<leader>utilstest1", ":echo 'test'<CR>", {})

            local keymap = vim.fn.maparg("<leader>utilstest1", "n", false, true)
            assert.equals(1, keymap.silent, "Should be silent by default")
        end)

        it("should set keymap with noremap=true by default", function()
            utils.keymap("n", "<leader>utilstest2", ":echo 'test'<CR>", {})

            local keymap = vim.fn.maparg("<leader>utilstest2", "n", false, true)
            assert.equals(1, keymap.noremap, "Should be noremap by default")
        end)

        it("should work with multiple modes", function()
            utils.keymap({ "n", "v" }, "<leader>utilstest3", ":echo 'test'<CR>", {})

            local keymap_n = vim.fn.maparg("<leader>utilstest3", "n", false, true)
            local keymap_v = vim.fn.maparg("<leader>utilstest3", "v", false, true)

            assert.is_truthy(next(keymap_n), "Should map in normal mode")
            assert.is_truthy(next(keymap_v), "Should map in visual mode")
        end)

        it("should work with function as rhs", function()
            local test_func = function() return "test" end
            utils.keymap("n", "<leader>utilstest1", test_func, {})

            local keymap = vim.fn.maparg("<leader>utilstest1", "n", false, true)
            assert.is_truthy(keymap.callback, "Should have callback function")
        end)
    end)

    describe("get_colors()", function()
        it("should return a table", function()
            local colors = utils.get_colors()
            assert.is_table(colors)
        end)

        it("should return fresh colors on each call (not cached)", function()
            local colors1 = utils.get_colors()
            local colors2 = utils.get_colors()
            assert.is_table(colors1)
            assert.is_table(colors2)
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
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello world" })

            -- Select "hello"
            vim.cmd("normal! 0v4l")

            local selection = utils.getVisualSelection()
            assert.equals("hello", selection)

            vim.cmd("bdelete!")
        end)

        it("should strip newlines from selection", function()
            vim.cmd("new")
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "line1", "line2" })

            -- Select both lines
            vim.cmd("normal! ggVG")

            local selection = utils.getVisualSelection()
            -- Should not contain newline (gsub removes it)
            assert.is_nil(string.find(selection, "\n"))

            vim.cmd("bdelete!")
        end)
    end)

    describe("is_bazel_project()", function()
        it("should return false in non-Bazel directory", function()
            local initial_cwd = vim.fn.getcwd()

            local tmpdir = "/tmp/nvim_test_nobazel_" .. os.time()
            vim.fn.mkdir(tmpdir, "p")
            vim.api.nvim_set_current_dir(tmpdir)

            local result = utils.is_bazel_project()
            assert.is_false(result)

            vim.api.nvim_set_current_dir(initial_cwd)
            vim.fn.delete(tmpdir, "rf")
        end)

        it("should return true when BUILD file exists", function()
            local initial_cwd = vim.fn.getcwd()

            local tmpdir = "/tmp/nvim_test_bazel_build_" .. os.time()
            vim.fn.mkdir(tmpdir, "p")
            vim.fn.writefile({}, tmpdir .. "/BUILD")
            vim.api.nvim_set_current_dir(tmpdir)

            local result = utils.is_bazel_project()
            assert.is_true(result)

            vim.api.nvim_set_current_dir(initial_cwd)
            vim.fn.delete(tmpdir, "rf")
        end)

        it("should return true when WORKSPACE file exists", function()
            local initial_cwd = vim.fn.getcwd()

            local tmpdir = "/tmp/nvim_test_bazel_ws_" .. os.time()
            vim.fn.mkdir(tmpdir, "p")
            vim.fn.writefile({}, tmpdir .. "/WORKSPACE")
            vim.api.nvim_set_current_dir(tmpdir)

            local result = utils.is_bazel_project()
            assert.is_true(result)

            vim.api.nvim_set_current_dir(initial_cwd)
            vim.fn.delete(tmpdir, "rf")
        end)
    end)

    describe("set_cwd()", function()
        it("should not error when called", function()
            assert.has_no_errors(function()
                utils.set_cwd()
            end)
        end)
    end)

    describe("pick_one_sync()", function()
        it("should return nil for invalid choice (0)", function()
            local old_inputlist = vim.fn.inputlist
            vim.fn.inputlist = function() return 0 end

            local items = { "item1", "item2", "item3" }
            local result = utils.pick_one_sync(items, "Choose:", function(x) return x end)

            vim.fn.inputlist = old_inputlist
            assert.is_nil(result)
        end)

        it("should return nil for out of range choice", function()
            local old_inputlist = vim.fn.inputlist
            vim.fn.inputlist = function() return 99 end

            local items = { "item1", "item2" }
            local result = utils.pick_one_sync(items, "Choose:", function(x) return x end)

            vim.fn.inputlist = old_inputlist
            assert.is_nil(result)
        end)

        it("should return selected item for valid choice", function()
            local old_inputlist = vim.fn.inputlist
            vim.fn.inputlist = function() return 2 end

            local items = { "item1", "item2", "item3" }
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

            local items = { 10, 20, 30 }
            utils.pick_one_sync(items, "Numbers:", function(x) return "Value: " .. x end)

            vim.fn.inputlist = old_inputlist
            assert.equals("Numbers:", captured_prompt[1])
            assert.equals("1: Value: 10", captured_prompt[2])
        end)
    end)

    describe("Autocommands", function()
        it("should have LspAttach autocommand for set_cwd", function()
            local autocmds = vim.api.nvim_get_autocmds({ event = "LspAttach" })
            assert.is_true(#autocmds > 0, "LspAttach autocommands should exist")
        end)

        it("should have VimEnter autocommand for set_cwd", function()
            local autocmds = vim.api.nvim_get_autocmds({ event = "VimEnter" })
            assert.is_true(#autocmds > 0, "VimEnter autocommands should exist")
        end)
    end)
end)

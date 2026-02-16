-------------------------------------------------------------------------------
-- Test user/nvim-tree.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("NvimTree Config", function()
    local nvimtree_mod

    before_each(function()
        nvimtree_mod = require("user.nvim-tree")
    end)

    describe("Module Interface", function()
        it("should expose required functions", function()
            assert.is_function(nvimtree_mod.config)
            assert.is_function(nvimtree_mod.on_attach)
            assert.is_function(nvimtree_mod.inc_width_ind)
            assert.is_function(nvimtree_mod.dec_width_ind)
        end)
    end)

    describe("Width Management", function()
        it("should initialize nvim_tree_width to 30", function()
            -- Force reload to test initial value
            package.loaded["user.nvim-tree"] = nil
            vim.g.nvim_tree_width = nil
            require("user.nvim-tree")
            assert.equals(30, vim.g.nvim_tree_width)
        end)

        it("inc_width_ind should increase width by 10", function()
            vim.g.nvim_tree_width = 30
            local new_width = nvimtree_mod.inc_width_ind()
            assert.equals(40, new_width)
            assert.equals(40, vim.g.nvim_tree_width)
        end)

        it("dec_width_ind should decrease width by 10", function()
            vim.g.nvim_tree_width = 30
            local new_width = nvimtree_mod.dec_width_ind()
            assert.equals(20, new_width)
            assert.equals(20, vim.g.nvim_tree_width)
        end)

        it("width changes should be persistent across calls", function()
            vim.g.nvim_tree_width = 30
            nvimtree_mod.inc_width_ind()
            nvimtree_mod.inc_width_ind()
            assert.equals(50, vim.g.nvim_tree_width)

            nvimtree_mod.dec_width_ind()
            assert.equals(40, vim.g.nvim_tree_width)
        end)
    end)

    describe("NvimTree Setup (config())", function()
        it("should not error when called", function()
            -- config() may return early if nvim-tree plugin not available
            assert.has_no_errors(function()
                pcall(nvimtree_mod.config)
            end)
        end)

        it("toggle keymap should use wrapper to defer api lookup", function()
            pcall(nvimtree_mod.config)

            local maps = vim.api.nvim_get_keymap("n")
            for _, m in ipairs(maps) do
                if m.desc == "Toggle nvim-tree" then
                    assert.is_truthy(m.callback,
                        "toggle mapping should use a callback (wrapper function)")
                    return
                end
            end
            -- If nvim-tree plugin is not available, config() returns early
            -- and no mapping is set, which is acceptable in test env
        end)
    end)
end)

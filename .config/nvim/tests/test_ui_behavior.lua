-- Test ACTUAL BEHAVIOR of UI plugins
describe("UI Behavior", function()
    describe("Lualine", function()
        it("should load and generate theme", function()
            local ok, mod = pcall(require, "user.lualine")
            assert.is_true(ok, "lualine module should load")
            
            if ok then
                local theme = mod.get_theme()
                assert.is_table(theme)
                
                -- Check mode-specific colors exist
                if next(theme) ~= nil then
                    assert.is_table(theme.normal)
                    assert.is_table(theme.insert)
                    assert.is_table(theme.visual)
                end
            end
        end)
    end)

    describe("NvimTree", function()
        it("should start with width of 30", function()
            require("user.nvim-tree")
            assert.equals(30, vim.g.nvim_tree_width)
        end)

        it("should increase width correctly", function()
            local mod = require("user.nvim-tree")
            vim.g.nvim_tree_width = 30
            
            local new_width = mod.inc_width_ind()
            assert.equals(40, new_width)
            assert.equals(40, vim.g.nvim_tree_width)
        end)

        it("should decrease width correctly", function()
            local mod = require("user.nvim-tree")
            vim.g.nvim_tree_width = 30
            
            local new_width = mod.dec_width_ind()
            assert.equals(20, new_width)
            assert.equals(20, vim.g.nvim_tree_width)
        end)

        it("should disable netrw when configured", function()
            local mod = require("user.nvim-tree")
            if mod.config then
                pcall(mod.config)
            end
            
            assert.equals(1, vim.g.loaded_netrw)
            assert.equals(1, vim.g.loaded_netrwPlugin)
        end)
    end)

    describe("Bufferline", function()
        it("should load without errors", function()
            assert.has_no_errors(function()
                require("user.bufferline")
            end)
        end)
    end)

    describe("WhichKey", function()
        it("should load without errors", function()
            assert.has_no_errors(function()
                require("user.which-key")
            end)
        end)
    end)

    describe("IndentBlankline", function()
        it("should load without errors", function()
            assert.has_no_errors(function()
                require("user.indent-blankline")
            end)
        end)
    end)
end)

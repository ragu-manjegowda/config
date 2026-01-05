-------------------------------------------------------------------------------
-- Test user/nvim-select-multi-line.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("NvimSelectMultiLine Config", function()
    local sml_mod

    before_each(function()
        sml_mod = require("user.nvim-select-multi-line")
    end)

    describe("Module Interface", function()
        it("should expose before function", function()
            assert.is_function(sml_mod.before)
        end)
    end)

    describe("NvimSelectMultiLine Setup (before())", function()
        before_each(function()
            pcall(sml_mod.before)
        end)

        it("should set <leader>v keymap for sml mode (user config)", function()
            local map = vim.fn.maparg("<leader>v", "n", false, true)
            assert.is_truthy(map.rhs or map.callback,
                "<leader>v should activate sml mode per user config")
        end)
    end)
end)

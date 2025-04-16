-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, diffview = pcall(require, "diffview")
    if not res then
        vim.notify("diffview not found", vim.log.levels.WARN)
        return
    end

    diffview.setup({
        view = {
            default = {
                winbar_info = true
            }
        }
    })

    local utils
    res, utils = pcall(require, "user.utils")
    if not res then
        vim.notify("Error loading user.utils", vim.log.levels.WARN)
        return
    end

    local opts = function(desc)
        return {
            desc = "diffview: " .. desc
        }
    end

    utils.keymap("n", "<leader>gstd",
        "<cmd>DiffviewOpen<CR>",
        opts("Diffview open git status"))
end

return M

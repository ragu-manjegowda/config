-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, bracketed = pcall(require, "mini.bracketed")
    if not res then
        vim.notify("mini.bracketed not found", vim.log.levels.ERROR)
        return
    end

    bracketed.setup({
        buffer = { suffix = "" },
        comment = { suffix = "/" },
        diagnostic = { suffix = "" },
        file = { suffix = "" },
        oldfile = { suffix = "" },
        undo = { suffix = "" },
        window = { suffix = "" },
        yank = { suffix = "" }
    })

    vim.api.nvim_create_user_command(
        "ToggleMiniBracketed",
        function()
            if vim.g.minibracketed_disable then
                vim.g.minibracketed_disable = false
            else
                vim.g.minibracketed_disable = true
            end
        end, {}
    )
end

return M

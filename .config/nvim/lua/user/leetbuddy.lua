-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()

    local res, leetbuddy = pcall(require, "leetbuddy")
    if not res then
        vim.notify("leetbuddy not found", vim.log.levels.ERROR)
        return
    end

    leetbuddy.setup({
        domain = "com",
        language = "cpp",
        keys = {
            select = "<CR>",
            reset = "<C-r>",
            easy = "<C-e>",
            medium = "<C-d>",
            hard = "<C-h>",
            accepted = "<C-a>",
            not_started = "<C-y>",
            tried = "<C-t>"
        }
    })
end

return M

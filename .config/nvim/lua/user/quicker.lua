-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, quicker = pcall(require, "quicker")
    if not res then
        vim.notify("quicker not found", vim.log.levels.ERROR)
        return
    end

    quicker.setup({
        use_default_opts = false,
        keys = {
            {
                ">",
                function()
                    quicker.expand({ before = 2, after = 2, add_to_existing = true })
                end,
                desc = "Expand quickfix context"
            },
            {
                "<",
                function()
                    quicker.collapse()
                end,
                desc = "Collapse quickfix context"
            }
        },
        edit = {
            autosave = "false"
        }
    })
end

return M

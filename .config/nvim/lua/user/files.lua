-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, files = pcall(require, "mini.files")
    if not res then
        vim.notify("mini.files not found", vim.log.levels.ERROR)
        return
    end

    files.setup()

    vim.api.nvim_create_user_command(
        'MiniFilesOpen',
        function()
            files.open()
        end, {}
    )

    vim.api.nvim_create_user_command(
        'ToggleMiniFiles',
        function()
            if vim.g.minifiles_disable then
                vim.g.minifiles_disable = false
            else
                vim.g.minifiles_disable = true
            end
        end, {}
    )
end

return M

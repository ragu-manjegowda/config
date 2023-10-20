-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, animate = pcall(require, "mini.animate")
    if not res then
        vim.notify("mini.animate not found", vim.log.levels.ERROR)
        return
    end

    animate.setup({
        resize = {
            enable = false
        },
        open = {
            enable = false
        },
        close = {
            enable = false
        }
    })

    vim.api.nvim_create_user_command(
        'ToggleMiniAnimate',
        function()
            if vim.g.animate_disable then
                vim.g.animate_disable = false
            else
                vim.g.animate_disable = true
            end
        end, {}
    )
end

return M

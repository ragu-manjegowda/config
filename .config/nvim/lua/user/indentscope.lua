-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    local res, indentscope = pcall(require, "mini.indentscope")
    if not res then
        vim.notify("mini.indentscope not found", vim.log.levels.ERROR)
        return
    end

    indentscope.setup({
        draw = {
            animation = indentscope.gen_animation.none()
        },
        symbol = ''
    })
end

return M

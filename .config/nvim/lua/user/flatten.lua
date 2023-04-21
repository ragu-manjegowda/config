-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.opts()
    return {
        window = {
            open = "tab"
        },
        callbacks = {
            post_open = function(_, winnr, _, _)
                require("user.fterm").__fterm_zsh()
                vim.api.nvim_set_current_win(winnr)
            end
        }
    }
end

return M

-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.opts()
    return {
        callbacks = {
            post_open = function(_, _, _, _)
            end
        },
        window = {
            open = "tab"
        }
    }
end

return M

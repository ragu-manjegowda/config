-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.before()
    vim.cmd [[
        nnoremap <leader>v :call sml#mode_on()<CR>
    ]]
end

return M

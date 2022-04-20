local vim = vim

local M = {}

function M.before()
    vim.cmd [[
        let g:indentLine_char_list = ['|', '¦', '┆', '┊']
        let g:indentLine_leadingSpaceChar = '·'
        let g:indentLine_leadingSpaceEnabled = 1
    ]]
end

return M

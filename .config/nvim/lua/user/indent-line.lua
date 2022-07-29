local vim = vim

local M = {}

function M.before()
    vim.cmd [[
        let g:indentLine_char_list = ['|', '¦', '┆', '┊']
        let g:indentLine_leadingSpaceChar = '·'
        let g:indentLine_leadingSpaceEnabled = 1
        let g:vim_json_conceal=0
        let g:markdown_syntax_conceal=0
    ]]
end

return M

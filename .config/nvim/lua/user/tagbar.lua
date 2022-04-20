local vim = vim

local M = {}

function M.before()
    vim.cmd [[

        nnoremap <silent><leader>tag :TagbarOpen f<CR>
        let g:tagbar_autoclose = 1
        let g:tagbar_ctags_options = ['NONE']
        let g:tagbar_show_linenumbers = 2
        let g:tagbar_show_tag_linenumbers = 2
        let g:tagbar_show_tag_count = 1

    ]]
end

return M

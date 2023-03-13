-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.config()
    vim.cmd [[
        let g:gutentags_enabled = 0
        let g:gutentags_cache_dir = expand('~/.cache/nvim/gutentags')
        let g:gutentags_gtags_dbpath = expand('~/.cache/nvim/gutentags')
        let g:gutentags_modules = ['ctags', 'gtags_cscope']
        let g:gutentags_generate_on_new = 1
        let g:gutentags_generate_on_missing = 1
        let g:gutentags_trace = 0
        let g:gutentags_define_advanced_commands = 1
        let g:gutentags_plus_switch = 1
        let g:gutentags_generate_on_write = 1
        let g:gutentags_generate_on_empty_buffer = 0
        let g:gutentags_ctags_auto_set_tags = 0
        let g:gutentags_project_root = [ '.gitignore', 'CONTRIBUTING.md' ]
        let g:gutentags_ctags_exclude_wildignore = 1
        let g:gutentags_ctags_exclude = [
            \ '.git', 'data/*', '*/bazel-*', 'bazel*', 'bazel-*', 'partners/', 'avddn/', 'apps/',
            \ 'av/', 'benchmarks/', 'ci/', 'doc/', 'private/', 'resources/', 'scripts', 'share',
            \ 'swig/', 'ux', '*/dazel*', 'dazel-out', '*/bazel*/', 'lib*.so', '*.log'
            \ ]

        if executable('rg')
            let g:gutentags_file_list_command = 'rg --files'
        endif

        " Clear the cache
        command! -nargs=0 GutentagsClearCache call system('rm ' . g:gutentags_cache_dir . '/*')

        " Remaps
        let g:gutentags_plus_nomap = 1

        " Find symbols
        noremap <silent> <leader>gsy :GscopeFind s <C-R><C-W><CR><C-W>T<CR>
        " Find definitions
        noremap <silent> <leader>gd :GscopeFind g <C-R><C-W><CR><C-W>T<CR>
        " Find called by this function
        noremap <silent> <leader>gc :GscopeFind d <C-R><C-W><CR><C-W>T<CR>
        " Find calling this function
        noremap <silent> <leader>gC :GscopeFind c <C-R><C-W><CR><C-W>T<CR>
        " Find files including this file
        noremap <silent> <leader>gi :GscopeFind i <C-R>=expand("<cfile>")<CR><CR><C-W>T<CR>
        " Find where this symbol is assigned value
        noremap <silent> <leader>ga :GscopeFind a <C-R><C-W><CR><C-W>T<CR>
    ]]

    local status_ok, whichkey = pcall(require, "which-key")
    if not status_ok then
        vim.notify("which-key not found", vim.log.levels.ERROR)
        return
    end

    -- Register mappings description with which-key
    whichkey.register({
        g = {
            name = "Gscope",
            sy = "Gscope find symbols",
            d = "Gscope find definitions",
            c = "Gscope called by this function",
            C = "Gscope calling this function",
            i = "Gscope files including this file",
            a = "Gscope symbol assigned value"
        },
    }, { prefix = "<leader>" })
end

return M

local vim = vim

local M = {}

function M.before()
    vim.cmd [[

        " Configure vim-session

        set sessionoptions=buffers,curdir,tabpages,winsize

        let g:session_directory = expand('~/.cache/nvim/sessions')
        " Don't autoload sessions on startup
        let g:session_autoload = 'no'
        " Don't prompt to save on exit
        let g:session_autosave = 'yes'
        let g:session_autosave_periodic = 1
        let g:session_autosave_silent = 1
        let g:session_verbose_messages = 0
        let g:session_command_aliases = 1
        let g:session_menu = 0


        function! FindSessionDirectory()
            let l:is_git_dir = system('echo -n $(git rev-parse --is-inside-work-tree)')
            if l:is_git_dir == 'true'
                let l:path = system('echo -n $(git rev-parse --show-toplevel)')
            else
                let l:path = getcwd()
            endif
            let l:path = substitute(path, '\v\/', '_', 'g')
            let l:path = substitute(path, '\v\.', '', 'g')
            return substitute(path, '[A-Z]', '\U&', 'g')
        endfunction

        let g:session_extension = ''
        let g:session_autosave_to = FindSessionDirectory()

    ]]
end


return M

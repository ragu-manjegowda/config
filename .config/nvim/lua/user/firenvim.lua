local vim = vim

local M = {}

function M.config()
    vim.cmd [[
        let g:firenvim_config = {
            \ 'localSettings': {
                \ '.*': {
                    \ 'takeover': 'never',
                \ },
            \ }
        \ }

        function! OnUIEnter(event) abort
            if 'Firenvim' ==# get(get(nvim_get_chan_info(a:event.chan), 'client', {}), 'name', '')
                :set laststatus=2
                " :set lines=70
                " :set columns=110
                " :LspStop

                let s:fontsize = 11

                function! AdjustFontSizeF(amount)
                    let s:fontsize = s:fontsize+a:amount
                    execute "set guifont=Hack\\ NF:h" . s:fontsize
                    call rpcnotify(0, 'Gui', 'WindowMaximized', 1)
                endfunction

                noremap  <C-=> :call AdjustFontSizeF(1)<CR>
                noremap  <C--> :call AdjustFontSizeF(-1)<CR>
                inoremap <C-=> :call AdjustFontSizeF(1)<CR>
                inoremap <C--> :call AdjustFontSizeF(-1)<CR>
            endif
        endfunction
        autocmd UIEnter * call OnUIEnter(deepcopy(v:event))
    ]]
end

return M

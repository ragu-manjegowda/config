-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

vim.cmd [[

augroup QuickFix
    " Open qf entry in vertical split
    au FileType qf nnoremap <buffer> <leader>v <C-w><CR><C-w>L
    " Open qf list in new tab
    au FileType qf nnoremap <buffer> <leader><Tab> <C-w><CR><C-w>T
augroup END

" Reference - https://stackoverflow.com/a/6496995
function! StripTrailingWhitespace()
    " Don't strip on these filetypes
    if &ft =~ 'mail' || &ft =~ 'markdown' || &ft =~ 'rmd' ||
        \ &ft =~ 'text' || &ft =~ 'rst'
        return
    endif
    %s/\s\+$//e
endfun
autocmd BufWritePre * call StripTrailingWhitespace()

" Disable line breaks for file type mail
function! DisableLineBreak()
    if &ft =~ 'mail'
        set wrap
        set linebreak
        set nolist  " list disables linebreak
        set textwidth=0
        set wrapmargin=0
        set fo-=t
    endif
endfun
autocmd VimEnter * call DisableLineBreak()

" Open man page
function! s:RaguCppMan()
    let old_isk = &iskeyword
    setl iskeyword+=:
    let str = expand("<cword>")
    let &l:iskeyword = old_isk
    execute system("tmux split-window cppman " . str)
endfunction
command! RaguCppMan :call s:RaguCppMan()
au FileType cpp nnoremap <leader>man :RaguCppMan<CR>

" Zoom / Restore window
function! s:ZoomToggle() abort
    if exists('t:zoomed') && t:zoomed
        execute t:zoom_winrestcmd
        let t:zoomed = 0
    else
        let t:zoom_winrestcmd = winrestcmd()
        resize
        vertical resize
        let t:zoomed = 1
    endif
endfunction
command! ZoomToggle call s:ZoomToggle()
nnoremap <silent> <leader>z :ZoomToggle<CR>


" Disable creating new file if doesn't exist
let g:fsnonewfiles = 1

" Switch between header and source file not in same directory
au BufEnter *.h let b:fswitchdst = 'c,_interface.cpp,cpp' |
    \ let b:fswitchlocs = 'reg:|include.*|src/**|' | let b:fswitchfnames = '/$/_interface/'
au BufEnter *.hpp let b:fswitchdst = 'cpp' | let b:fswitchlocs = 'reg:|include.*|src/**|,./impl'
au BufEnter *.cpp let b:fswitchdst = 'hpp' | let b:fswitchlocs = 'reg:|include.*|src/**|,../'
au BufEnter *_interface.cpp let b:fswitchdst = 'h' | let b:fswitchfnames = '/_interface$//'
nnoremap <silent> <leader>oh :FSTab<CR>

" Delete all other lines except ones containing args
function! GrepQuickFix(pat)
    let all = getqflist()
    for d in all
        if bufname(d['bufnr']) !~ a:pat && d['text'] !~ a:pat
            call remove(all, index(all,d))
        endif
    endfor
    call setqflist(all)
endfunction

command! -nargs=* QFGrep call GrepQuickFix(<q-args>)

" Delete all other lines except ones containing args
function! RemoveQuickFix(pat)
    let all = getqflist()
    for d in all
        if bufname(d['bufnr']) =~ a:pat || d['text'] =~ a:pat
            call remove(all, index(all,d))
        endif
    endfor
    call setqflist(all)
endfunction

command! -nargs=* QFRemove call RemoveQuickFix(<q-args>)

" Sort quick fix list
function! s:CompareQuickfixEntries(i1, i2)
    if bufname(a:i1.bufnr) == bufname(a:i2.bufnr)
        return a:i1.lnum == a:i2.lnum ? 0 : (a:i1.lnum < a:i2.lnum ? -1 : 1)
    else
        return bufname(a:i1.bufnr) < bufname(a:i2.bufnr) ? -1 : 1
    endif
endfunction

function! s:SortUniqQFList()
    let sortedList = sort(getqflist(), 's:CompareQuickfixEntries')
    let uniqedList = []
    let last = ''
    for item in sortedList
        let this = bufname(item.bufnr) . "\t" . item.lnum
        if this !=# last
            call add(uniqedList, item)
            let last = this
            endif
    endfor
    call setqflist(uniqedList)
endfunction

command! QFSort call s:SortUniqQFList()

]]

vim.api.nvim_create_augroup("bufcheck", { clear = true })

-- reload config file on change
vim.api.nvim_create_autocmd(
    { "BufWritePost" },
    {
        group   = "bufcheck",
        pattern = vim.env.MYVIMRC,
        command = "silent source %"
    }
)

-- highlight yanks
vim.api.nvim_create_autocmd(
    { "TextYankPost" },
    {
        group    = "bufcheck",
        pattern  = "*",
        callback = function()
            vim.highlight.on_yank { timeout = 500 }
        end
    }
)

-- start terminal in insert mode
vim.api.nvim_create_autocmd(
    { "TermOpen" },
    {
        group   = "bufcheck",
        pattern = "*",
        command = "startinsert | set winfixheight"
    }
)

-- pager mappings for Manual
vim.api.nvim_create_autocmd(
    { "FileType" },
    {
        group    = "bufcheck",
        pattern  = { "man", "help" },
        callback = function()
            vim.keymap.set("n", "<enter>", "K", { buffer = true })
            vim.keymap.set("n", "<backspace>", "<c-o>", { buffer = true })
        end
    }
)

-- Return to last edit position when opening files
-- vim.api.nvim_create_autocmd("BufReadPost",  {
--     group    = "bufcheck",
--     pattern  = "*",
--     callback = function()
--       if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
--             vim.fn.setpos(".", vim.fn.getpos("'\""))
--             vim.api.nvim_feedkeys('zz', 'n', true)
--         end
--     end
-- })

-- Go imports and formatting_sync on save
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.go" },
    callback = function()
        vim.lsp.buf.formatting_sync(nil, 3000)
    end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.go" },
    callback = function()
        ---@diagnostic disable-next-line: missing-parameter
        local params = vim.lsp.util.make_range_params(nil, vim.lsp.util._get_offset_encoding())
        params.context = { only = { "source.organizeImports" } }

        ---@diagnostic disable-next-line: param-type-mismatch
        local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
        for _, res in pairs(result or {}) do
            for _, r in pairs(res.result or {}) do
                if r.edit then
                    ---@diagnostic disable-next-line: missing-parameter
                    vim.lsp.util.apply_workspace_edit(r.edit, vim.lsp.util._get_offset_encoding())
                else
                    vim.lsp.buf.execute_command(r.command)
                end
            end
        end
    end,
})

-- Mason update
vim.api.nvim_create_autocmd('User', {
    pattern = 'MasonToolsUpdateCompleted',
    callback = function()
        vim.schedule(function()
            print "Mason-tool-installer has finished"
        end)
    end,
})

-- Disable global status line for mergetool
-- Do it by simply counting the number of windows
vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
        local windows = vim.api.nvim_tabpage_list_wins(0)
        if #windows == 4 then
            vim.opt.laststatus = 2
            local buf_name = { '%=LOCAL%=', '%=BASE%=', '%=REMOTE%=' }
            for i, win in ipairs(windows) do
                if i == 4 then
                    return
                end
                vim.api.nvim_win_set_option(win, "statusline", buf_name[i])
            end
        end
    end,
})

-- Toggle hlsearch b/w enter and exiting search mode
local events = { 'CmdlineEnter', 'CmdlineLeave' }

vim.api.nvim_create_autocmd(events, {
    pattern = "/,\\?",
    callback = function(args)
        if args.event == 'CmdlineEnter' then
            vim.opt.hlsearch = true
        elseif args.event == 'CmdlineLeave' then
            vim.opt.hlsearch = false
        end
    end,
})

-- Set match pairs for c, cpp
-- Remove `-` from iskeyword to avoid not matching pointer variables
-- Ex: `this->pointer` considers `this-` but not `this` when matching words
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'cpp', 'c' },
    callback = function()
        vim.opt.mps:append "=:;"
        vim.opt.iskeyword:remove "-"
    end,
})

-- "fix gf functionality inside .lua files"
-- credit: https://github.com/LunarVim/LunarVim
vim.api.nvim_create_autocmd('FileType', {
    pattern = { "lua" },
    callback = function()
        ---@diagnostic disable: assign-type-mismatch
        -- credit: https://github.com/sam4llis/nvim-lua-gf
        vim.opt_local.include = [[\v<((do|load)file|require|reload)[^''"]*[''"]\zs[^''"]+]]
        vim.opt_local.includeexpr = "substitute(v:fname,'\\.','/','g')"
        vim.opt_local.suffixesadd:prepend ".lua"
        vim.opt_local.suffixesadd:prepend "init.lua"

        for _, path in pairs(vim.api.nvim_list_runtime_paths()) do
            vim.opt_local.path:append(path .. "/lua")
        end
    end
})

-- Resize window when vim is resized
-- credit: https://github.com/LunarVim/LunarVim
vim.api.nvim_create_autocmd('VimResized', {
    pattern = "*",
    command = "tabdo wincmd ="
})

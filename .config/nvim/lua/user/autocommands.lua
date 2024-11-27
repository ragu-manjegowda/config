-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local opts = { buffer = true, silent = true }
local keymap = vim.keymap.set

local vim = vim

vim.cmd [[

" Zoom / Restore window
function! s:ToggleZoom() abort
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
command! ToggleZoom call s:ToggleZoom()
nnoremap <silent> <leader>z :ToggleZoom<CR>


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

-- add keymap for QuickFix list
vim.api.nvim_create_autocmd(
    { "FileType" },
    {
        group    = "bufcheck",
        pattern  = { "qf" },
        callback = function()
            keymap("n", "<leader>v", "<C-w><CR><C-w>L", opts)
            keymap("n", "<leader><Tab>", "<C-w><CR><C-w>T", opts)
        end
    }
)

-- remove trailing whitespaces
vim.api.nvim_create_autocmd(
    { "BufWritePre" },
    {
        group    = "bufcheck",
        pattern  = '*',
        callback = function()
            local ft = vim.bo.filetype
            if ft == "mail" or ft == "markdown" or ft == "rmd" or ft == "text"
                or ft == "rst" then
                return
            end
            -- Save current cursor position
            local save_cursor = vim.fn.getcurpos()
            vim.cmd(":%s/\\s\\+$//e")
            -- Set cursor position to the saved position
            vim.fn.setpos('.', save_cursor)
        end
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

-- pager mappings for Manual
vim.api.nvim_create_autocmd(
    { "FileType" },
    {
        group    = "bufcheck",
        pattern  = { "man", "help" },
        callback = function()
            keymap("n", "<enter>", "K", opts)
            keymap("n", "<backspace>", "<c-o>", opts)
        end
    }
)

-- Mason update
vim.api.nvim_create_autocmd('User', {
    pattern = 'MasonToolsUpdateCompleted',
    callback = function()
        vim.schedule(function()
            print "Mason-tool-installer has finished"
        end)
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

-- Fix gf functionality inside .lua files
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

-- Disable displaying leading spaces for certain filetypes
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "checkhealth", "fugitive", "gitcommit", "text" },
    callback = function()
        vim.opt.list = false
        vim.opt.listchars:remove "lead"
        vim.opt_local.textwidth = 72
    end
})

-- Set custom fold options for Markdown files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "rmd", "rst" },
    callback = function()
        vim.opt_local.conceallevel = 2;
        vim.opt_local.concealcursor = "n";
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldlevel = 2
    end
})

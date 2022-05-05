local vim = vim

local M = {}

function M.config()
    vim.cmd [[
        augroup GitStatus
            au filetype fugitive nmap <buffer> <leader>gdv :Gtabedit <Plug><cfile><Bar>Gvdiffsplit!<CR>
        augroup END

        " Git status in new tab
        nnoremap <silent> <leader>gca :tab Git commit --amend<CR>
        nnoremap <silent> <leader>gcan :Git commit --amend --no-edit<CR>
        nnoremap <silent> <leader>gcm :tab Git commit -s<CR>
        nnoremap <silent> <leader>gfa :Git fetch --all --prune<CR>
        nnoremap <silent> <leader>glog :GcLog!<Bar>cclose<Bar>tab copen<CR>
        " nnoremap <silent> <leader>glogf :tab Git log --oneline --decorate --graph -- %<CR>
        nnoremap <silent> <leader>glogp :tab Git log --pretty=full<CR>
        nnoremap <silent> <leader>gpulla :Git pull --rebase --autostash<CR>
        nnoremap <silent> <leader>gpush :Git push<CR>
        nnoremap <silent> <leader>gst :tab G<CR>
        " nnoremap <silent> <leader>gstash :GcLog -g stash<Bar>cclose<Bar>tab copen<CR>
        " nnoremap <silent> <leader>gstasha :Git stash apply <C-R><C-G><CR>

        " Resolve merge conflict
        nnoremap <silent> <leader>gpf :diffget //2<CR>
        nnoremap <silent> <leader>gpj :diffget //3<CR>
    ]]

    local status_ok, whichkey = pcall(require, "which-key")
    if not status_ok then
        return
    end

    -- Register mappings description with which-key
    local wk = require("which-key")

    wk.register({
        g = {
            name = "Git",
            co = "Git commits in telescope float window",
            dv = "Git diff view in new tab",
            log = "Git log commits in new quick fix tab",
            logf = "Git log current file in telescope float window",
            logp = "Git log pretty in new tab",
            pf = "Git merge apply left diff",
            pj = "Git merge apply right diff",
            stash = "Git stash list in telescope float window"
        },
    }, { prefix = "<leader>" })
end

return M

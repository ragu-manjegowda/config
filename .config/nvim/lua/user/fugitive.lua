-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

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
        nnoremap <silent> <leader>glogf :tab Git log --oneline --decorate --graph -- %<CR>
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
        vim.notify("which-key not found", vim.log.levels.ERROR)
        return
    end

    -- Register mappings description with which-key
    whichkey.add({
        { "<leader>g",      group = "Git" },
        { "<leader>gco",    desc = "Git commits in telescope float window" },
        { "<leader>gdv",    desc = "Git diff view in new tab" },
        { "<leader>glog",   desc = "Git log commits in new quick fix tab" },
        { "<leader>glogf",  desc = "Git log current file in telescope float window" },
        { "<leader>glogp",  desc = "Git log pretty in new tab" },
        { "<leader>gpf",    desc = "Git merge apply left diff" },
        { "<leader>gpj",    desc = "Git merge apply right diff" },
        { "<leader>gstash", desc = "Git stash list in telescope float window" },
    })
end

return M

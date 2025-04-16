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
    ]]

    local res, utils = pcall(require, "user.utils")
    if not res then
        vim.notify("Error loading user.utils", vim.log.levels.ERROR)
        return
    end

    local opts = function(desc)
        return {
            desc = "fugitive: " .. desc
        }
    end

    utils.keymap("n", "<leader>gfa", "<cmd>Git fetch --all --prune<CR>",
        opts("Git fetch --all --prune"))

    utils.keymap("n", "<leader>glog", "<cmd>GcLog!<Bar>cclose<Bar>tab copen<CR>",
        opts("Git log commits in new quick fix tab"))

    utils.keymap("n", "<leader>glogf", "<cmd>tab Git log --oneline --decorate --graph -- %<CR>",
        opts("Git log current file in new quick fix tab"))

    utils.keymap("n", "<leader>gpulla", "<cmd>Git pull --rebase --autostash<CR>",
        opts("Git pull --rebase --autostash"))

    utils.keymap("n", "<leader>gst", "<cmd>tab G<CR>",
        opts("Git tab status"))

    utils.keymap("n", "<leader>gpf", "<cmd>diffget //2<CR>",
        opts("Git merge apply left diff"))

    utils.keymap("n", "<leader>gpj", "<cmd>diffget //3<CR>",
        opts("Git merge apply right diff"))

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

-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

vim.g["nvim_tree_width"] = 30

local g = vim.g

function M.inc_width_ind()
    g.nvim_tree_width = g.nvim_tree_width + 10
    return g.nvim_tree_width
end

function M.dec_width_ind()
    g.nvim_tree_width = g.nvim_tree_width - 10
    return g.nvim_tree_width
end

function M.on_attach(bufnr)
    local res, api, utils

    res, api = pcall(require, "nvim-tree.api")
    if not res then
        vim.notify("nvim-tree.api not found", vim.log.levels.ERROR)
    else
        res, utils = pcall(require, "user.utils")
        if not res then
            vim.notify("Error loading user.utils", vim.log.levels.ERROR)
            return
        end
    end

    local function opts(desc)
        return {
            desc = "nvim-tree: " .. desc,
            buffer = bufnr,
            nowait = true,
        }
    end

    api.config.mappings.default_on_attach(bufnr)

    utils.keymap("n", "<leader><Tab>", api.node.open.tab,
        opts("open in new tab"))

    utils.keymap("n", "<leader>tgr", api.git.reload,
        opts("reload nvim-tree git"))

    utils.keymap("n", "<leader>tmn", api.marks.navigate.next,
        opts("navigate to next mark"))

    utils.keymap("n", "<leader>tmp", api.marks.navigate.prev,
        opts("navigate to previous mark"))
end

function M.config()
    local res, nvim_tree = pcall(require, "nvim-tree")
    if not res then
        vim.notify("nvim-tree not found", vim.log.levels.ERROR)
        return
    end

    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    local api = require("nvim-tree.api")
    local utils = require("user.utils")

    utils.keymap("n", "<leader>tt", function() api.tree.toggle() end,
        { desc = "Toggle nvim-tree" })

    nvim_tree.setup {
        on_attach = M.on_attach,
        update_focused_file = {
            enable = true,
            update_cwd = false,
            ignore_list = {}
        },
        view = {
            width = 30,
            side = "left",
            number = true,
            relativenumber = true
        }
    }
end

return M

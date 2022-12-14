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

function M.config()
    local map = vim.api.nvim_set_keymap
    local opts = {noremap = true, silent = true}

    map("n", "<leader>tgr", '<cmd>lua require("nvim-tree.api").git.reload()<CR>', opts)
    map("n", "<leader>tmn", '<cmd>lua require("nvim-tree.api").marks.navigate.next()<CR>', opts)
    map("n", "<leader>tmp", '<cmd>lua require("nvim-tree.api").marks.navigate.prev()<CR>', opts)
    map('n', '<leader>tt', '<cmd>lua require("nvim-tree").toggle()<CR>', opts)

    local res, nvim_tree = pcall(require, "nvim-tree")
    if not res then
        vim.notify("nvim-tree not found", vim.log.levels.ERROR)
        return
    end

    local tree_cb = require "nvim-tree.config".nvim_tree_callback

    local list = {
        { key = { "<leader>v"},     cb = tree_cb("vsplit"), mode = "n" },
        { key = { "<leader><Tab>"}, cb = tree_cb("tabnew"), mode = "n" }
    }

    nvim_tree.setup {
        update_focused_file = {
            -- enables the feature
            enable      = true,
            -- update the root directory of the tree to the one of the folder containing the file if the file is not under the current root directory
            -- only relevant when `update_focused_file.enable` is true
            update_cwd  = false,
            -- list of buffer names / filetypes that will not update the cwd if the file isn't found under the current root directory
            -- only relevant when `update_focused_file.update_cwd` is true and `update_focused_file.enable` is true
            ignore_list = {}
        },
        view = {
            width = 30,
            side = 'left',
            number = true,
            relativenumber = true,
            mappings = {
              custom_only = false,
              list = list
            }
        }
    }
end

return M

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

function M.config()
    local res, api = pcall(require, "nvim-tree.api")
    if not res then
        vim.notify("nvim-tree.api not found", vim.log.levels.ERROR)
    else
        local map = vim.keymap.set
        local opts = function(desc)
            return {
                desc = 'nvim-tree: ' .. desc, noremap = true, silent = true
            }
        end

        map("n", "<leader><Tab>", api.node.open.tab, opts("open in new tab"))
        map("n", "<leader>tgr", api.git.reload, opts("reload nvim-tree git"))

        map("n", "<leader>tmn", api.marks.navigate.next,
            opts("navigate to next mark"))
        map("n", "<leader>tmp", api.marks.navigate.prev,
            opts("navigate to previous mark"))

        map('n', '<leader>tt', api.tree.toggle, opts("toggle nvim-tree"))
    end

    local nvim_tree
    res, nvim_tree = pcall(require, "nvim-tree")
    if not res then
        vim.notify("nvim-tree not found", vim.log.levels.ERROR)
        return
    end

    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    nvim_tree.setup {
        update_focused_file = {
            -- enables the feature
            enable      = true,
            -- update the root directory of the tree to the one of the
            -- folder containing the file if the file is not under the
            -- current root directory only relevant when
            -- `update_focused_file.enable` is true
            update_cwd  = false,
            -- list of buffer names / filetypes that will not update the
            -- cwd if the file isn't found under the current root directory
            -- only relevant when `update_focused_file.update_cwd` is true
            -- and `update_focused_file.enable` is true
            ignore_list = {}
        },
        view = {
            width = 30,
            side = 'left',
            number = true,
            relativenumber = true,
            mappings = {
                custom_only = false,
            }
        }
    }
end

return M

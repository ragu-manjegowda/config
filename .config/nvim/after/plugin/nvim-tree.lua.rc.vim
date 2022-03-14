
nnoremap <leader>tt :NvimTreeToggle<CR>
nnoremap <leader>tr :NvimTreeRefresh<CR>

let g:nvim_tree_width = 30

lua <<EOF

local g = vim.g

function _G.inc_width_ind()
    g.nvim_tree_width = g.nvim_tree_width + 10
    return g.nvim_tree_width
end

function _G.dec_width_ind()
    g.nvim_tree_width = g.nvim_tree_width - 10
    return g.nvim_tree_width
end

local tree_cb = require "nvim-tree.config".nvim_tree_callback

local list = {
  { key = {"<leader>l"}, cb = "<CMD>exec ':NvimTreeResize ' . v:lua.inc_width_ind()<CR>"},
  { key = {"<leader>h"}, cb = "<CMD>exec ':NvimTreeResize ' . v:lua.dec_width_ind()<CR>"},
  { key = { "<leader>v"},     cb = tree_cb("vsplit"), mode = "n" },
  { key = { "<leader><Tab>"}, cb = tree_cb("tabnew"), mode = "n" }
}

require'nvim-tree'.setup {
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
    auto_resize = false,
    mappings = {
      custom_only = false,
      list = list
    }
  }
}

EOF


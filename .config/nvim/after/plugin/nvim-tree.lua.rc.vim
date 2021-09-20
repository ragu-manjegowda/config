
nnoremap <leader>tt :NvimTreeToggle<CR>
nnoremap <leader>tr :NvimTreeRefresh<CR>

lua <<EOF

local tree_cb = require'nvim-tree.config'.nvim_tree_callback

-- default mappings
vim.g.nvim_tree_bindings = {
  { key = "<leader>v",     cb = tree_cb("vsplit") },
  { key = "<leader><Tab>", cb = tree_cb("tabnew") },
}

EOF


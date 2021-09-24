
nnoremap <leader>tt :NvimTreeToggle<CR>
nnoremap <leader>tr :NvimTreeRefresh<CR>

let g:nvim_tree_follow = 1
let g:nvim_tree_width = 30

lua <<EOF

local tree_cb = require'nvim-tree.config'.nvim_tree_callback

-- default mappings
vim.g.nvim_tree_bindings = {
  { key = "<leader>v",     cb = tree_cb("vsplit") },
  { key = "<leader><Tab>", cb = tree_cb("tabnew") },
}

EOF

fun! IncWidthInd()
  let g:nvim_tree_width = (g:nvim_tree_width + 10)
  return g:nvim_tree_width
endf

fun! DecWidthInd()
  let g:nvim_tree_width = (g:nvim_tree_width - 10)
  return g:nvim_tree_width
endf

" Icrease or decrease tree width with left and right arrow keys
augroup SetWidth
    au filetype NvimTree nnoremap <buffer> <Left> :exe ":NvimTreeResize ".DecWidthInd()<cr>
    au filetype NvimTree nnoremap <buffer> <Right> :exe ":NvimTreeResize ".IncWidthInd()<cr>
augroup END


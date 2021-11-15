
lua << EOF

local ignore_these = {
  '.git/.*',
  'bazel-sdk/.*',
  'bazel-out/*',
  'bazel-bin/*',
}

local actions = require("telescope.actions")
require("telescope").setup({
    defaults = {

        mappings = {
            i = {
                ["<C-x>"] = false,
                ["<C-q>"] = actions.send_to_qflist,
                ["<leader><Tab>"] = actions.select_tab,
                ["<leader>v"] = actions.select_vertical,
            },
            n = {
                ["q"] = actions.close
            },
        },

        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
        file_sorter = require("telescope.sorters").get_fzy_sorter,
        color_devicons = true,
        prompt_prefix = '🔍 ',
        sorting_strategy = 'ascending',
        layout_strategy = 'vertical', --flex
        file_ignore_patterns = ignore_these,

        layout_config = {
            preview_cutoff = 1,
        },
    },
    extensions = {
        fzf = {
            override_generic_sorter = false,
            override_file_sorter = true,
        },
    },
})

require("telescope").load_extension("fzf")

function _G.explorer()
    if current_buffer and is_directory(current_buffer) then
        require("telescope.builtin").file_browser({
        cwd = "%:p:h",
        hidden = true,
        file_ignore_patterns = { ".git" },
        })
    else
        require("telescope.builtin").file_browser({
        hidden = true,
        file_ignore_patterns = { ".git" },
        })
    end
end

vim.cmd "autocmd User TelescopePreviewerLoaded setlocal number"

EOF

" Telescope fuzzy finder shortcuts
nnoremap <leader>ps :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <leader>pw :lua require('telescope.builtin').grep_string { search = vim.fn.expand("<cword>") }<CR>
nnoremap <leader>pW :lua require('telescope.builtin').grep_string({ search = "'" .. vim.fn.expand('<cword>') })<CR>
nnoremap <leader>pf :lua require('telescope.builtin').find_files()<CR>
nnoremap <leader>pq :lua require('telescope.builtin').quickfix()<CR>
nnoremap <leader>pb :lua explorer()<CR>



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

        vimgrep_arguments = {
            "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "-g",
          "!.git"
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
nnoremap <silent> <leader>pb :lua require('telescope.builtin').buffers()<CR>
nnoremap <silent> <leader>pf :lua require('telescope.builtin').find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})<CR>
nnoremap <silent> <leader>ph :lua require('telescope.builtin').help_tags()<CR>
nnoremap <silent> <leader>po :lua explorer()<CR>
nnoremap <silent> <leader>pq :lua require('telescope.builtin').quickfix()<CR>
nnoremap <silent> <leader>ps :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <silent> <leader>pw :lua require('telescope.builtin').grep_string { search = vim.fn.expand("<cword>") }<CR>
nnoremap <silent> <leader>pW :lua require('telescope.builtin').grep_string({ search = "'" .. vim.fn.expand('<cword>') })<CR>

" Git shortcuts
nnoremap <silent> <leader>gco :lua require('telescope.builtin').git_commits()<CR>
nnoremap <silent> <leader>glogf :lua require('telescope.builtin').git_bcommits()<CR>
" nnoremap <silent> <leader>glogp :lua require('telescope.builtin').git_commits({ git_command = {'git', 'log', '--pretty=full'}})<CR>
" nnoremap <silent> <leader>gst :lua require('telescope.builtin').git_status()<CR>
nnoremap <silent> <leader>gstash :lua require('telescope.builtin').git_stash()<CR>


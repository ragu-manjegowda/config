
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
        fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true,
        },
    },
})

require("telescope").load_extension("fzy_native")

EOF


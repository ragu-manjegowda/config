local vim = vim

local M = {}

function M.grep()
    require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})
end

function M.grep_word()
    require('telescope.builtin').grep_string({ search = vim.fn.expand("<cword>")})
end

function M.grep_word_exact()
    require('telescope.builtin').grep_string({ search = "'" .. vim.fn.expand("<cword>")})
end

function M.before()
    vim.cmd "autocmd User TelescopePreviewerLoaded setlocal number"

    local map = vim.api.nvim_set_keymap
    local opts = {noremap = true, silent = true}

    -- Telescope fuzzy finder shortcuts
    map('n', '<leader>pb', '<cmd>lua require("telescope.builtin").buffers()<CR>', opts)
    map('n', '<leader>pc', '<cmd>lua require("telescope.builtin").command_history()<CR>', opts)
    map('n', '<leader>pf', '<cmd>lua require("telescope.builtin").find_files({ find_command = {"rg", "--files", "--hidden", "-g", "!.git" }})<CR>', opts)
    map('n', '<leader>ph', '<cmd>lua require("telescope.builtin").help_tags()<CR>', opts)
    map('n', '<leader>pj', '<cmd>lua require("telescope.builtin").jumplist()<CR>', opts)
    map('n', '<leader>pm', '<cmd>lua require("telescope.builtin").man_pages()<CR>', opts)
    map('n', '<leader>po', '<cmd>lua require("telescope.builtin").explorer()<CR>', opts)
    map('n', '<leader>pq', '<cmd>lua require("telescope.builtin").quickfix()<CR>', opts)
    map('n', '<leader>ps', '<cmd>lua require("user.telescope").grep()<CR>', opts)
    map('n', '<leader>pt', '<cmd>lua require("telescope.builtin").treesitter()<CR>', opts)
    map('n', '<leader>pw', '<cmd>lua require("user.telescope").grep_word()<CR>', opts)
    map('n', '<leader>pW', '<cmd>lua require("user.telescope").grep_word_exact()<CR>', opts)

    -- Git shortcuts
    map('n', '<leader>gco',    '<cmd>lua require("telescope.builtin").git_commits()<CR>', opts)
    map('n', '<leader>glogf',  '<cmd>lua require("telescope.builtin").git_bcommits()<CR>', opts)
    -- map('n', '<leader>glogp',  '<cmd>lua require("telescope.builtin").git_commits({ git_command = {"git", "log", "--pretty=full"}})<CR>', opts)
    -- map('n', '<leader>gst',    '<cmd>lua require("telescope.builtin").git_status()<CR>', opts)
    map('n', '<leader>gstash', '<cmd>lua require("telescope.builtin").git_stash()<CR>', opts)
end

function M.config()
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
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<C-x>"] = false,
                    ["<C-q>"] = actions.send_to_qflist,
                    ["<leader><Tab>"] = actions.select_tab,
                    ["<leader>v"] = actions.select_vertical,
                },
                n = {
                    ["q"] = actions.close,
                    ["<leader><Tab>"] = actions.select_tab,
                    ["<leader>v"] = actions.select_vertical,
                },
            },

            file_previewer = require("telescope.previewers").vim_buffer_cat.new,
            grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
            qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
            file_sorter = require("telescope.sorters").get_fzy_sorter,
            color_devicons = true,
            sorting_strategy = 'ascending',
            layout_strategy = 'vertical', --flex
            file_ignore_patterns = ignore_these,
            prompt_prefix = " ",
            selection_caret = " ",
            path_display = { "truncate" },

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
end

return M

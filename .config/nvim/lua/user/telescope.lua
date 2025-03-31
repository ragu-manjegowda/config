-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

local util_res, utils = pcall(require, "user.utils")
if not util_res then
    vim.notify("utils not found", vim.log.levels.ERROR)
    return
end

function M.getVisualSelection()
    return utils.getVisualSelection()
end

function M.grep(options)
    local opts = options or {}

    if not options or options.grep_word == nil then
        local text = M.getVisualSelection()
        if text ~= '' then
            opts.search = text
        else
            opts.search = vim.fn.input("Grep For > ")
        end
    end

    require('telescope.builtin').grep_string(opts)
end

function M.grep_folder()
    local opts = {}
    opts.search_dirs = {}
    opts.search_dirs[1] = vim.fn.input("Grep in Directory > ",
        ---@diagnostic disable-next-line: redundant-parameter
        vim.fn.expand("%:p:h") .. "/", "file")
    M.grep(opts)
end

function M.grep_word()
    local opts = {}
    opts.grep_word = vim.fn.expand("<cword>")
    M.grep(opts)
end

function M.grep_word_exact()
    local opts = {}
    opts.word_match = "-w"
    opts.grep_word = vim.fn.expand("<cword>")
    M.grep(opts)
end

function M.current_buffer_fuzzy_find()
    local opts = {}

    local text = M.getVisualSelection()
    if text ~= '' then
        opts.default_text = text
    else
        opts.default_text = nil
    end

    require('telescope.builtin').current_buffer_fuzzy_find(opts)
end

function M.live_grep(options)
    local opts = options or {}

    local text = M.getVisualSelection()
    if text ~= '' then
        opts.default_text = text
    else
        opts.default_text = nil
    end

    if opts.folder_path ~= nil then
        opts.default_text = '"' .. (opts.default_text or '') .. '" ' .. opts.folder_path
    end

    require("telescope").extensions.live_grep_args.live_grep_args(opts)
end

function M.live_grep_current_buffer_folder()
    local opts = {}
    opts.folder_path = vim.fn.expand("%:p:h")

    M.live_grep(opts)
end

function M.find_files()
    local opts = {}

    opts.find_command = { "rg", "--files", "--hidden", "-g", "!.git" }

    local text = M.getVisualSelection()
    if text ~= '' then
        opts.default_text = text
    else
        opts.default_text = nil
    end

    require("telescope.builtin").find_files(opts)
end

function M.before()
    vim.cmd "autocmd User TelescopePreviewerLoaded setlocal number"

    local map = vim.keymap.set

    -- Telescope fuzzy finder shortcuts
    map({ 'n', 'v' }, '<leader>bs',
        '<cmd>lua require("user.telescope").current_buffer_fuzzy_find()<CR>',
        { silent = true, desc = 'Telescope buffer fuzzy find' })

    map('n', '<leader>dlb', '<cmd>lua require("telescope").extensions.dap.list_breakpoints{}<CR>',
        { silent = true, desc = 'DAP list_breakpoints' })

    map('n', '<leader>dbt', '<cmd>lua require("telescope").extensions.dap.frames{}<CR>',
        { silent = true, desc = 'DAP stack backtrace' })

    map({ 'n', 'v' }, '<leader>fg',
        '<cmd>lua require("user.telescope").live_grep()<CR>',
        { silent = true, desc = 'Telescope live grep with regex' })

    map({ 'n', 'v' }, '<leader>fgp',
        '<cmd>lua require("user.telescope").live_grep_current_buffer_folder()<CR>',
        { silent = true, desc = 'Telescope live grep current buffer folder with regex' })

    map('n', '<leader>pb', '<cmd>lua require("telescope.builtin").buffers()<CR>',
        { silent = true, desc = 'Telescope list project buffers' })

    map('n', '<leader>pc', '<cmd>lua require("telescope.builtin").command_history()<CR>',
        { silent = true, desc = 'Telescope command_history' })

    map({ 'n', 'v' }, '<leader>pf',
        '<cmd>lua require("user.telescope").find_files()<CR>',
        { silent = true, desc = 'Telescope find_files' })

    map('n', '<leader>ph', '<cmd>lua require("telescope.builtin").help_tags()<CR>',
        { silent = true, desc = 'Telescope help_tags' })

    map('n', '<leader>pj', '<cmd>lua require("telescope.builtin").jumplist()<CR>',
        { silent = true, desc = 'Telescope jumplist' })

    map('n', '<leader>pk', '<cmd>lua require("telescope.builtin").keymaps()<CR>',
        { silent = true, desc = 'Telescope keymaps' })

    map('n', '<leader>pm', '<cmd>lua require("telescope.builtin").man_pages()<CR>',
        { silent = true, desc = 'Telescope man_pages' })

    map('n', '<leader>pq', '<cmd>lua require("telescope.builtin").quickfix()<CR>',
        { silent = true, desc = 'Telescope quickfix' })

    map('n', '<leader>pr', '<cmd>lua require("telescope.builtin").registers()<CR>',
        { silent = true, desc = 'Telescope registers' })

    map({ 'n', 'v' }, '<leader>ps', '<cmd>lua require("user.telescope").grep()<CR>',
        { silent = true, desc = 'Telescope grep' })

    map({ 'n', 'v' }, '<leader>psf', '<cmd>lua require("user.telescope").grep_folder()<CR>',
        { silent = true, desc = 'Telescope grep in directories' })

    map('n', '<leader>pt', '<cmd>lua require("telescope.builtin").treesitter()<CR>',
        { silent = true, desc = 'Telescope treesitter' })

    map({ 'n', 'v' }, '<leader>pw', '<cmd>lua require("user.telescope").grep_word()<CR>',
        { silent = true, desc = 'Telescope grep_word' })

    map({ 'n', 'v' }, '<leader>pW', '<cmd>lua require("user.telescope").grep_word_exact()<CR>',
        { silent = true, desc = 'Telescope grep_word_exact' })

    -- LSP
    -- map('n', '<leader>lA', '<cmd>lua vim.lsp.buf.code_action()<CR>',
    --     { silent = true, desc = 'LSP code_action' })
    map('n', '<leader>lic', '<cmd>lua require("telescope.builtin").lsp_incoming_calls()<CR>',
        { silent = true, desc = 'LSP incoming_calls' })
    map('n', '<leader>loc', '<cmd>lua require("telescope.builtin").lsp_outgoing_calls()<CR>',
        { silent = true, desc = 'LSP outgoing_calls' })
    -- map('n', '<leader>ld', '<cmd>lua require("telescope.builtin").lsp_definitions()<CR>',
    --     { silent = true, desc = 'LSP definitions' })
    map('n', '<leader>oe', '<cmd>lua require("telescope.builtin").diagnostics()<CR>',
        { silent = true, desc = 'LSP diagnostics preview in Telescope' })
    -- map('n', '<leader>li', '<cmd>lua require("telescope.builtin").lsp_implementations()<CR>',
    --     { silent = true, desc = 'LSP implementations' })
    -- map('n', '<leader>lr', '<cmd>lua require("telescope.builtin").lsp_references()<CR>',
    --     { silent = true, desc = 'LSP references' })
    -- map('n', '<leader>lt', '<cmd>lua require("telescope.builtin").lsp_type_definitions()<CR>',
    --     { silent = true, desc = 'LSP type_definitions' })

    -- Git shortcuts
    map('n', '<leader>gco', '<cmd>lua require("telescope.builtin").git_commits()<CR>',
        { silent = true, desc = 'Git checkout commit' })
    map('n', '<leader>glogft', '<cmd>lua require("telescope.builtin").git_bcommits()<CR>',
        { silent = true, desc = 'Git log file with telescope' })
    -- map('n', '<leader>glogp',  '<cmd>lua ' ..
    --     'require("telescope.builtin").git_commits({ ' ..
    --     'git_command = {"git", "log", "--pretty=full"}})<CR>', opts)
    -- map('n', '<leader>gst',    '<cmd>lua require("telescope.builtin").git_status()<CR>', opts)
    map('n', '<leader>gstash', '<cmd>lua require("telescope.builtin").git_stash()<CR>',
        { silent = true, desc = 'Git list stash' })

    -- Spell suggest
    map('n', 'z=', '<cmd>lua require("telescope.builtin").spell_suggest()<CR>',
        { silent = true, desc = 'Spell suggest' })

    -- Undo Tree
    map('n', '<leader>ut',
        '<cmd>lua require("telescope").extensions.undo.undo()<CR>',
        { silent = true, desc = 'Open undo tree in telescope' })
end

function M.config()
    local ignore_these = {
        '.git/.*',
        'bazel-sdk/.*',
        'bazel-out/*',
        'bazel-bin/*',
    }

    local res, telescope = pcall(require, "telescope")
    if not res then
        vim.notify("telescope not found", vim.log.levels.ERROR)
        return
    end

    ---@diagnostic disable-next-line: assign-type-mismatch
    res, _ = pcall(require, "plenary")
    if not res then
        vim.notify("plenary not found", vim.log.levels.ERROR)
        return
    end

    R = function(name)
        require("plenary.reload").reload_module(name)
        return require(name)
    end

    local actions = require("telescope.actions")
    local actions_state = require("telescope.actions.state")
    local lga_actions = require("telescope-live-grep-args.actions")
    local undo_actions = require("telescope-undo.actions")

    local function yank_entry()
        local entry = actions_state.get_selected_entry()
        vim.fn.setreg("*", entry.value)
        print("Yanked:", entry.value)
    end

    telescope.setup({
        defaults = {
            border = false,

            mappings = {
                i = {
                    ["<C-a>"] = { "<Home>", type = "command" },
                    ["<C-e>"] = actions.edit_command_line,
                    ["<C-f>"] = actions.to_fuzzy_refine,
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<C-l>"] = actions.results_scrolling_right,
                    ["<C-h>"] = actions.results_scrolling_left,
                    ["<C-d>"] = actions.results_scrolling_down,
                    ["<C-u>"] = actions.results_scrolling_up,
                    ["<C-q>"] = actions.send_to_qflist,
                    ["<C-y>"] = yank_entry,
                    ["<M-b>"] = { "<S-Left>", type = "command" },
                    ["<M-f>"] = { "<S-Right>", type = "command" },
                    ["<M-j>"] = actions.preview_scrolling_down,
                    ["<M-k>"] = actions.preview_scrolling_up,
                    ["<M-l>"] = actions.preview_scrolling_right,
                    ["<M-h>"] = actions.preview_scrolling_left,
                    ["<M-/>"] = R "telescope".extensions.hop.hop,
                    ["<leader><Tab>"] = actions.select_tab,
                    ["<leader>v"] = actions.select_vertical,
                },
                n = {
                    ["<C-a>"] = { "<Home>", type = "command" },
                    ["<C-e>"] = actions.edit_command_line,
                    ["<C-f>"] = actions.to_fuzzy_refine,
                    ["<C-q>"] = actions.send_to_qflist,
                    ["<C-l>"] = actions.results_scrolling_right,
                    ["<C-h>"] = actions.results_scrolling_left,
                    ["<C-d>"] = actions.results_scrolling_down,
                    ["<C-u>"] = actions.results_scrolling_up,
                    ["<C-y>"] = yank_entry,
                    ["<M-b>"] = { "<S-Left>", type = "command" },
                    ["<M-f>"] = { "<S-Right>", type = "command" },
                    ["<M-j>"] = actions.preview_scrolling_down,
                    ["<M-k>"] = actions.preview_scrolling_up,
                    ["<M-l>"] = actions.preview_scrolling_right,
                    ["<M-h>"] = actions.preview_scrolling_left,
                    ["<M-/>"] = R "telescope".extensions.hop.hop,
                    ["q"] = actions.close,
                    ["<leader><Tab>"] = actions.select_tab,
                    ["<leader>v"] = actions.select_vertical,
                },
            },

            color_devicons = true,
            sorting_strategy = 'ascending',
            layout_strategy = 'vertical', --flex
            file_ignore_patterns = ignore_these,
            prompt_prefix = " ",
            selection_caret = " ",
            path_display = { "filename_first" },

            layout_config = {
                preview_cutoff = 1,
                width = 0.95
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
            live_grep_args = {
                auto_quoting = true, -- enable/disable auto-quoting
                -- override default mappings
                -- default_mappings = {},
                mappings = { -- extend mappings
                    i = {
                        ["<C-i>"] = lga_actions.quote_prompt(),
                    }
                }
            },
            undo = {
                mappings = { -- extend mappings
                    i = {
                        ["<CR>"] = undo_actions.restore,
                        ["<C-a>"] = undo_actions.yank_additions,
                        ["<C-r>"] = undo_actions.yank_deletions
                    }
                }
            }
        },
    })

    telescope.load_extension("dap")
    telescope.load_extension("fzf")
    telescope.load_extension("hop")
    telescope.load_extension("live_grep_args")
    telescope.load_extension("ui-select")
    telescope.load_extension("undo")
end

return M

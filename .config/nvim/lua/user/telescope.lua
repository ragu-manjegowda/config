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

    local opts = function(desc)
        return {
            desc = "telescope: " .. desc
        }
    end

    -- Telescope fuzzy finder shortcuts
    utils.keymap({ 'n', 'v' }, '<leader>bs',
        '<cmd>lua require("user.telescope").current_buffer_fuzzy_find()<CR>',
        opts('buffer fuzzy find'))

    utils.keymap('n', '<leader>dlb',
        '<cmd>lua require("telescope").extensions.dap.list_breakpoints{}<CR>',
        opts('DAP list breakpoints'))

    utils.keymap('n', '<leader>dbt',
        '<cmd>lua require("telescope").extensions.dap.frames{}<CR>',
        opts('DAP backtrace'))

    utils.keymap({ 'n', 'v' }, '<leader>fg',
        '<cmd>lua require("user.telescope").live_grep()<CR>',
        opts('live grep with regex'))

    utils.keymap({ 'n', 'v' }, '<leader>fgp',
        '<cmd>lua require("user.telescope").live_grep_current_buffer_folder()<CR>',
        opts('live grep current buffer folder with regex'))

    utils.keymap('n', '<leader>pb',
        '<cmd>lua require("telescope.builtin").buffers()<CR>',
        opts('project list buffers'))

    utils.keymap('n', '<leader>pc',
        '<cmd>lua require("telescope.builtin").command_history()<CR>',
        opts('project command history'))

    utils.keymap({ 'n', 'v' }, '<leader>pf',
        '<cmd>lua require("user.telescope").find_files()<CR>',
        opts('project find files'))

    utils.keymap('n', '<leader>ph',
        '<cmd>lua require("telescope.builtin").help_tags()<CR>',
        opts('project help tags'))

    utils.keymap('n', '<leader>pj',
        '<cmd>lua require("telescope.builtin").jumplist()<CR>',
        opts('project jumplist'))

    utils.keymap('n', '<leader>pk',
        '<cmd>lua require("telescope.builtin").keymaps()<CR>',
        opts('project keymaps'))

    utils.keymap('n', '<leader>pm',
        '<cmd>lua require("telescope.builtin").man_pages()<CR>',
        opts('project man pages'))

    utils.keymap('n', '<leader>pq',
        '<cmd>lua require("telescope.builtin").quickfix()<CR>',
        opts('project quickfix buffers'))

    utils.keymap('n', '<leader>pr',
        '<cmd>lua require("telescope.builtin").registers()<CR>',
        opts('project registers'))

    utils.keymap({ 'n', 'v' }, '<leader>ps',
        '<cmd>lua require("user.telescope").grep()<CR>',
        opts('project search'))

    utils.keymap({ 'n', 'v' }, '<leader>psf',
        '<cmd>lua require("user.telescope").grep_folder()<CR>',
        opts('project search in directories'))

    utils.keymap('n', '<leader>pt',
        '<cmd>lua require("telescope.builtin").treesitter()<CR>',
        opts('current buffer treesitter symbols'))

    utils.keymap({ 'n', 'v' }, '<leader>pw',
        '<cmd>lua require("user.telescope").grep_word()<CR>',
        opts('project search word'))

    utils.keymap({ 'n', 'v' }, '<leader>pW',
        '<cmd>lua require("user.telescope").grep_word_exact()<CR>',
        opts('project search word_exact'))

    -- LSP
    utils.keymap('n', '<leader>lic',
        '<cmd>lua require("telescope.builtin").lsp_incoming_calls()<CR>',
        opts('project incoming calls'))

    utils.keymap('n', '<leader>loc',
        '<cmd>lua require("telescope.builtin").lsp_outgoing_calls()<CR>',
        opts('project outgoing calls'))

    utils.keymap('n', '<leader>oe',
        '<cmd>lua require("telescope.builtin").diagnostics()<CR>',
        opts('LSP diagnostics in Telescope'))

    -- Git shortcuts
    utils.keymap('n', '<leader>glogt',
        '<cmd>lua require("telescope.builtin").git_commits()<CR>',
        opts('Git list commits'))

    utils.keymap('n', '<leader>glogft',
        '<cmd>lua require("telescope.builtin").git_bcommits()<CR>',
        opts('Git log current file commits'))

    -- Spell suggest
    utils.keymap('n', 'z=',
        '<cmd>lua require("telescope.builtin").spell_suggest()<CR>',
        opts('Spell suggest'))

    -- Undo Tree
    utils.keymap('n', '<leader>ut',
        '<cmd>lua require("telescope").extensions.undo.undo()<CR>',
        opts('Open undo tree'))
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

-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()
    local res, gitsigns = pcall(require, "gitsigns")
    if not res then
        vim.notify("gitsigns not found", vim.log.levels.ERROR)
        return
    end

    gitsigns.setup {
        signs                   = {
            add          = {
                text = '│'
            },
            change       = {
                text = '│'
            },
            delete       = {
                text = '_'
            },
            topdelete    = {
                text = '‾'
            },
            changedelete = {
                text = '~'
            },
        },
        signcolumn              = true,            -- Toggle with `:Gitsigns toggle_signs`
        numhl                   = true,            -- Toggle with `:Gitsigns toggle_numhl`
        linehl                  = false,           -- Toggle with `:Gitsigns toggle_linehl`
        diff_opts               = {
            algorithm = "patience"
        },
        word_diff               = true,           -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir            = {
            interval = 1000,
            follow_files = true
        },
        attach_to_untracked     = true,
        current_line_blame      = false,           -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
        },
        sign_priority           = 6,
        update_debounce         = 100,
        status_formatter        = nil,           -- Use default
        max_file_length         = 40000,
        preview_config          = {
            -- Options passed to nvim_open_win
            border = 'rounded',
            style = 'minimal',
            relative = 'cursor',
            row = 0,
            col = 1
        },
        on_attach               = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            -- Navigation
            map('n', ']h', function()
                if vim.wo.diff then return ']c' end
                vim.schedule(function() gs.nav_hunk("next", { target = "unstaged" }) end)
                return '<Ignore>'
            end, { expr = true, desc = "Navigate to next unstaged hunk" })

            map('n', '[h', function()
                if vim.wo.diff then return '[c' end
                vim.schedule(function() gs.nav_hunk("prev", { target = "unstaged" }) end)
                return '<Ignore>'
            end, { expr = true, desc = "Navigate to prev unstaged hunk" })

            map('n', ']hs', function()
                if vim.wo.diff then return ']c' end
                vim.schedule(function() gs.nav_hunk("next", { target = "staged" }) end)
                return '<Ignore>'
            end, { expr = true, desc = "Navigate to next staged hunk" })

            map('n', '[hs', function()
                if vim.wo.diff then return '[c' end
                vim.schedule(function() gs.nav_hunk("prev", { target = "staged" }) end)
                return '<Ignore>'
            end, { expr = true, desc = "Navigate to prev staged hunk" })

            -- Actions
            map('n', '<leader>hp', gs.preview_hunk)
            map('n', '<leader>gbl', gs.toggle_current_line_blame)

            -- Text object
            map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end
    }
end

return M

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
        signs                             = {
            add          = {
                hl = 'GitSignsAdd', text = '│',
                numhl = 'GitSignsAddNr', linehl = 'GitSignsAddLn'
            },
            change       = {
                hl = 'GitSignsChange', text = '│',
                numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn'
            },
            delete       = {
                hl = 'GitSignsDelete', text = '_',
                numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn'
            },
            topdelete    = {
                hl = 'GitSignsDelete', text = '‾',
                numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn'
            },
            changedelete = {
                hl = 'GitSignsChange', text = '~',
                numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn'
            },
        },
        signcolumn                        = true, -- Toggle with `:Gitsigns toggle_signs`
        numhl                             = true, -- Toggle with `:Gitsigns toggle_numhl`
        linehl                            = false, -- Toggle with `:Gitsigns toggle_linehl`
        diff_opts                         = {
            algorithm = "patience"
        },
        word_diff                         = true, -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir                      = {
            interval = 1000,
            follow_files = true
        },
        attach_to_untracked               = true,
        current_line_blame                = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts           = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
        },
        current_line_blame_formatter_opts = {
            relative_time = false
        },
        sign_priority                     = 6,
        update_debounce                   = 100,
        status_formatter                  = nil, -- Use default
        max_file_length                   = 40000,
        preview_config                    = {
            -- Options passed to nvim_open_win
            border = 'single',
            style = 'minimal',
            relative = 'cursor',
            row = 0,
            col = 1
        },
        yadm                              = {
            enable = false
        },
        on_attach                         = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            -- Navigation
            map('n', ']h', function()
                if vim.wo.diff then return ']c' end
                vim.schedule(function() gs.next_hunk() end)
                return '<Ignore>'
            end, { expr = true })

            map('n', '[h', function()
                if vim.wo.diff then return '[c' end
                vim.schedule(function() gs.prev_hunk() end)
                return '<Ignore>'
            end, { expr = true })

            -- Actions
            map('n', '<leader>hp', gs.preview_hunk)
            map('n', '<leader>gbl', gs.toggle_current_line_blame)

            -- Text object
            map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end
    }
end

return M

-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

M.get_theme = function()
    local colors = {
        base3   = vim.g.gui_base3,
        base2   = vim.g.gui_base2,
        base1   = vim.g.gui_base1,
        base0   = vim.g.gui_base0,
        base00  = vim.g.gui_base00,
        base01  = vim.g.gui_base01,
        base02  = vim.g.gui_base02,
        base03  = vim.g.gui_base03,
        yellow  = vim.g.gui_yellow,
        orange  = vim.g.gui_orange,
        red     = vim.g.gui_red,
        magenta = vim.g.gui_magenta,
        violet  = vim.g.gui_violet,
        blue    = vim.g.gui_blue,
        cyan    = vim.g.gui_cyan,
        green   = vim.g.gui_green,
    }

    return {
        normal = {
            a = { fg = colors.base3, bg = colors.magenta, gui = "bold" },
            b = { fg = colors.base2, bg = colors.base01 },
            c = { fg = colors.base1, bg = colors.base02 },
        },
        insert = { a = { fg = colors.base3, bg = colors.green, gui = "bold" } },
        visual = { a = { fg = colors.base3, bg = colors.yellow, gui = "bold" } },
        replace = { a = { fg = colors.base3, bg = colors.blue, gui = "bold" } },
        inactive = {
            a = { fg = colors.base3, bg = colors.base00, gui = "bold" },
            b = { fg = colors.base2, bg = colors.base01 },
            c = { fg = colors.base1, bg = colors.base02 },
        },
    }
end

M.config = function()
    local res, lualine = pcall(require, "lualine")
    if not res then
        vim.notify("lualine not found", vim.log.levels.ERROR)
        return
    end

    --- Get search count
    ---@param opts {count: boolean, cond: boolean}
    ---@return string | boolean
    local function getSearch(opts)
        -- Check if noice plugin is loaded
        local noice_exists, noice = pcall(require, "noice")

        if noice_exists then
            if opts.cond then
                return noice.api.status.search.has
            end

            if opts.count then
                return noice.api.status.search.get
            end
        end
        return (opts.count and false) or (opts.count and "")
    end

    lualine.setup {
        options = {
            theme = M.get_theme(),
            disabled_filetypes = {
                statusline = {
                    "NvimTree"
                }
            },
            ignore_focus = {
                "NvimTree"
            },
            always_divide_middle = true,
            globalstatus = false,
        },
        sections = {
            lualine_b = {
                "branch"
            },
            lualine_c = {
                "filename",
                {
                    "diff",
                    symbols = {
                        added = " ",
                        modified = " ",
                        removed = " "
                    },
                },
                {
                    "diagnostics",
                    symbols = {
                        error = " ",
                        warn = " ",
                        info = " ",
                        hint = " "
                    },
                }
            },
            lualine_x = {
                {
                    getSearch({ count = true }),
                    cond = getSearch({ cond = true }),
                },
                "lsp_status",
                "encoding"
            },
            lualine_y = {
                "filetype",
                "progress"
            }
        },
        inactive_sections = {
            lualine_b = { "diff" },
            lualine_x = { "progress" },
            lualine_y = { "location" },
        },
        extensions = {}
    }

    vim.api.nvim_set_hl(0, "StatusLine", { reverse = false })
    vim.api.nvim_set_hl(0, "StatusLineNC", { reverse = false })

    vim.api.nvim_set_hl(0, "LuaLineDiffAdd",
        {
            fg = vim.g.gui_green,
            bold = true
        })

    vim.api.nvim_set_hl(0, "LuaLineDiffChange",
        {
            fg = vim.g.gui_yellow,
            bold = true
        })

    vim.api.nvim_set_hl(0, "LuaLineDiffDelete",
        {
            fg = vim.g.gui_red,
            bold = true
        })

    vim.api.nvim_create_user_command(
        "ToggleLualine",
        function()
            lualine.refresh()
        end, {}
    )
end

return M

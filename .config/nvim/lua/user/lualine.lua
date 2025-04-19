-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

M.get_theme = function()
    local colors = require("user.utils").get_colors()

    if colors == nil then
        return {}
    end

    return {
        normal = {
            a = {
                fg = colors.bg1, bg = colors.blue, gui = "bold"
            },
            b = {
                fg = colors.bg0, bg = colors.fg1, gui = "bold"
            },
            c = {
                fg = colors.fg0, bg = colors.bg1
            }
        },
        insert = {
            a = {
                fg = colors.bg1, bg = colors.green, gui = "bold"
            }
        },
        visual = {
            a = {
                fg = colors.bg1, bg = colors.yellow, gui = "bold"
            }
        },
        replace = {
            a = {
                fg = colors.bg1, bg = colors.magenta, gui = "bold"
            }
        },
        inactive = {
            a = {
                fg = colors.bg0, bg = colors.fg2, gui = "bold"
            },
            b = {
                fg = colors.bg0, bg = colors.fg2
            },
            c = {
                fg = colors.fg1, bg = colors.bg1
            }
        }
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
                    sources = { "nvim_diagnostic", "nvim_lsp" },
                    symbols = {
                        error = " ",
                        warn = " ",
                        info = " ",
                        hint = " "
                    }
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

    vim.api.nvim_create_user_command(
        "ToggleLualine",
        function()
            lualine.refresh()
        end, {}
    )
end

return M

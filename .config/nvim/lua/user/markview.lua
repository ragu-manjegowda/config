-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

function M.config()
    local res, markview = pcall(require, "markview")
    if not res then
        vim.notify("markview not found", vim.log.levels.ERROR)
        return
    end

    markview.setup({
        preview = {
            modes = { "c", "n", "no", "v" }
        },
        --- Configuration for custom block quotes
        block_quotes = {
            ["Reference"] = {
                hl = "MarkviewBlockQuoteNote",
                preview = " References",
                preview_hl = nil,
                title = true,
                icon = " ",
                border = "▋",
                border_hl = nil
            },
            ["References"] = {
                hl = "MarkviewBlockQuoteNote",
                preview = " References",
                preview_hl = nil,
                title = true,
                icon = " ",
                border = "▋",
                border_hl = nil
            },
            ["Resource"] = {
                hl = "MarkviewBlockQuoteSpecial",
                preview = " Resources",
                preview_hl = nil,
                title = true,
                icon = " ",
                border = "▋",
                border_hl = nil
            },
            ["Resources"] = {
                hl = "MarkviewBlockQuoteSpecial",
                preview = " Resources",
                preview_hl = nil,
                title = true,
                icon = " ",
                border = "▋",
                border_hl = nil
            }
        },
        highlight_groups = {
            ["ZZ"] = function()
                return {
                    {
                        group_name = "MarkviewHeading1",
                        value = {
                            fg = tonumber(vim.g.gui_red:sub(2), 16),
                            bg = tonumber(vim.g.gui_base02:sub(2), 16)
                        }
                    },
                    {
                        group_name = "MarkviewHeading2",
                        value = {
                            fg = vim.g.gui_green,
                            bg = vim.g.gui_base02
                        }
                    },
                    {
                        group_name = "MarkviewHeading3",
                        value = {
                            fg = vim.g.gui_yellow,
                            bg = vim.g.gui_base02
                        }
                    },
                    {
                        group_name = "MarkviewHeading4",
                        value = {
                            fg = vim.g.gui_orange,
                            bg = vim.g.gui_base02
                        }
                    },
                    {
                        group_name = "MarkviewHeading5",
                        value = {
                            fg = vim.g.gui_cyan,
                            bg = vim.g.gui_base02
                        }
                    },
                    {
                        group_name = "MarkviewCode",
                        value = {
                            bg = vim.g.gui_base02
                        },
                    },
                    {
                        group_name = "MarkviewInlineCode",
                        value = {
                            fg = vim.g.gui_cyan,
                            bg = vim.g.gui_base02
                        }
                    }
                }
            end
        }
    })

    ---@type integer Current buffer.
    local buffer = vim.api.nvim_get_current_buf();

    local got_spec, spec = pcall(require, "markview.spec");
    local got_util, utils = pcall(require, "markview.utils");

    if got_spec == false then
        --- Markview most likely not loaded.
        --- no point in going forward.
        return;
    elseif got_util == false then
        --- Same as above.
        return;
    end

    -- Fold text creator.
    ---@return string | table
    _G.heading_foldtext = function()
        --- Start & end of the current fold.
        --- Note: These are 1-indexed!
        ---@type integer, integer
        local from, to = vim.v.foldstart, vim.v.foldend;

        --- Starting line
        ---@type string
        local line = vim.api.nvim_buf_get_lines(0, from - 1, from, false)[1];

        if line:match("^[%s%>]*%#+") == nil then
            --- Fold didn't start on a heading.
            return vim.fn.foldtext();
        end

        --- Heading configuration table.
        ---@diagnostic disable-next-line: undefined-doc-name
        ---@type markdown.headings?
        local main_config = spec.get({ "markdown", "headings" }, { fallback = nil });

        if not main_config then
            --- Headings are disabled.
            return vim.fn.foldtext();
        end

        --- Indentation, markers & the content of a heading.
        ---@type string, string, string
        local indent, marker, content = line:match("^([%s%>]*)(%#+)(.*)$");
        --- Heading level.
        ---@type integer
        local level = marker:len();

        ---@diagnostic disable-next-line: undefined-doc-name
        ---@type headings.atx
        local config = spec.get({ "heading_" .. level }, {
            source = main_config,
            fallback = nil,

            --- This part isn't needed unless the user
            --- does something with these parameters.
            eval_args = {
                buffer,
                {
                    class = "markdown_atx_heading",
                    marker = marker,

                    text = { marker .. content },
                    range = {
                        row_start = from - 1,
                        row_end = from,

                        col_start = #indent,
                        col_end = #line
                    }
                }
            }
        });

        --- Amount of spaces to add per heading level.
        ---@type integer
        local shift_width = spec.get({ "shift_width" }, { source = main_config, fallback = 0 });

        if not config then
            --- Config not found.
            return vim.fn.foldtext();
            ---@diagnostic disable-next-line: undefined-field
        elseif config.style == "simple" then
            return {
                ---@diagnostic disable-next-line: undefined-field
                { marker .. content, utils.set_hl(config.hl) },

                {
                    string.format(" 󰘖 %d", to - from),
                    utils.set_hl(string.format("Palette%dFg", 7 - level))
                }
            };
            ---@diagnostic disable-next-line: undefined-field
        elseif config.style == "label" then
            --- We won't implement alignment for the sake
            --- of keeping things simple.

            local shift = string.rep(" ", level * #shift_width);

            return {
                ---@diagnostic disable-next-line: undefined-field
                { shift,                      utils.set_hl(config.hl) },
                ---@diagnostic disable-next-line: undefined-field
                { config.corner_left or "",   utils.set_hl(config.corner_left_hl or config.hl) },
                ---@diagnostic disable-next-line: undefined-field
                { config.padding_left or "",  utils.set_hl(config.padding_left_hl or config.hl) },
                ---@diagnostic disable-next-line: undefined-field
                { config.icon or "",          utils.set_hl(config.padding_left_hl or config.hl) },
                ---@diagnostic disable-next-line: undefined-field
                { content:gsub("^%s", ""),    utils.set_hl(config.hl) },
                ---@diagnostic disable-next-line: undefined-field
                { config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
                ---@diagnostic disable-next-line: undefined-field
                { config.corner_right or "",  utils.set_hl(config.corner_right_hl or config.hl) },

                {
                    string.format(" 󰘖 %d", to - from),
                    utils.set_hl(string.format("Palette%dFg", 7 - level))
                }
            };
            ---@diagnostic disable-next-line: undefined-field
        elseif config.style == "icon" then
            local shift = string.rep(" ", level * shift_width);

            return {
                ---@diagnostic disable-next-line: undefined-field
                { shift,                   utils.set_hl(config.hl) },
                ---@diagnostic disable-next-line: undefined-field
                { config.icon or "",       utils.set_hl(config.padding_left_hl or config.hl) },
                ---@diagnostic disable-next-line: undefined-field
                { content:gsub("^%s", ""), utils.set_hl(config.hl) },

                {
                    string.format(" 󰘖 %d", to - from),
                    utils.set_hl(string.format("Palette%dFg", 7 - level))
                }
            };
        else
            return "";
        end
    end

    -- Set custom fold options for Markdown files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "rmd", "rst" },
        callback = function()
            vim.opt_local.conceallevel = 2;
            vim.opt_local.concealcursor = "n";
            vim.opt_local.fillchars = "fold: ,foldopen:,foldclose:";
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldtext = "v:lua.heading_foldtext()"
            vim.opt_local.foldlevel = 2
        end
    })
end

return M

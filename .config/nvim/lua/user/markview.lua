-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}
local saved_leading_spaces = {}

-- listchars is window-local: change only the leading-space marker, preserving
-- tabs/trailing-space markers and the window's original setting for raw text.
local function leading_spaces(window, preview)
    if not vim.api.nvim_win_is_valid(window) then return end
    vim.api.nvim_win_call(window, function()
        if preview then
            if not saved_leading_spaces[window] then
                saved_leading_spaces[window] = {
                    lead = vim.opt_local.listchars:get().lead or vim.opt_global.listchars:get().lead
                }
            end
            vim.opt_local.listchars:remove "lead"
        elseif saved_leading_spaces[window] then
            local lead = saved_leading_spaces[window].lead
            saved_leading_spaces[window] = nil
            if lead and vim.g.u_list_chars_set ~= false then
                vim.opt_local.listchars:append({ lead = lead })
            end
        end
    end)
end

function M.config()
    local res, markview = pcall(require, "markview")
    if not res then
        vim.notify("markview not found", vim.log.levels.ERROR)
        return
    end

    local preview_modes = { "c", "n", "no" }
    local default_callbacks = require("markview.spec").default.preview.callbacks
    local callbacks = {}
    for _, event in ipairs({ "on_enable", "on_disable", "on_detach", "on_mode_change" }) do
        local default = default_callbacks[event]
        local can_preview = event == "on_enable" or event == "on_mode_change"
        callbacks[event] = function(buffer, windows, mode)
            if default then default(buffer, windows, mode) end
            local preview = can_preview and vim.tbl_contains(preview_modes, mode or vim.fn.mode())
            for _, window in ipairs(windows) do
                leading_spaces(window, preview)
            end
        end
    end
    callbacks.on_splitview_open = function(source, buffer, window)
        default_callbacks.on_splitview_open(source, buffer, window)
        leading_spaces(window, true)
    end
    callbacks.on_splitview_close = function(_, _, window)
        leading_spaces(window, false)
    end

    markview.setup({
        preview = {
            modes = preview_modes,
            callbacks = callbacks
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
        }
    })

    -- Restore raw-buffer options when a window is reused, and synchronize new
    -- splits of an already attached buffer (which do not trigger on_enable).
    local group = vim.api.nvim_create_augroup("markview_leading_spaces", { clear = true })
    local function sync_window()
        local window = vim.api.nvim_get_current_win()
        local buffer = vim.api.nvim_win_get_buf(window)
        local state = require("markview.state")
        local buffer_state = state.get_buffer_state(buffer, false)
        local preview = state.enabled() and state.buf_attached(buffer)
            and buffer_state and buffer_state.enable
            and buffer ~= state.get_splitview_source()
            and vim.tbl_contains(preview_modes, vim.fn.mode())
        if window == state.get_splitview_window({}, false) then preview = true end
        leading_spaces(window, preview)
    end
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
        group = group,
        callback = sync_window
    })
    vim.api.nvim_create_autocmd("BufWinLeave", {
        group = group,
        callback = function() leading_spaces(vim.api.nvim_get_current_win(), false) end
    })
    vim.api.nvim_create_autocmd("WinClosed", {
        group = group,
        callback = function(args) saved_leading_spaces[tonumber(args.match)] = nil end
    })
    for _, window in ipairs(vim.api.nvim_list_wins()) do
        vim.api.nvim_win_call(window, sync_window)
    end

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

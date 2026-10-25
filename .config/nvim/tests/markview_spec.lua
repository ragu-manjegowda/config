-------------------------------------------------------------------------------
-- Test user/markview.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("Markview Config", function()
    local markview_mod

    before_each(function()
        markview_mod = require("user.markview")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(markview_mod.config)
        end)
    end)

    describe("Markview Setup (config())", function()
        it("should not error when called", function()
            assert.has_no_errors(function()
                markview_mod.config()
            end)
        end)
    end)

    describe("Preview leading-space markers", function()
        local callbacks, state, buffer, window, original_buffer
        local original_global, original_local, original_toggle, original_list
        local extra_windows, extra_buffers

        before_each(function()
            markview_mod.config()
            callbacks = require("markview.spec").get({ "preview", "callbacks" }, { ignore_enable = true })
            state = require("markview.state")
            state.enable(true)
            window = vim.api.nvim_get_current_win()
            original_buffer = vim.api.nvim_get_current_buf()
            original_global = vim.opt_global.listchars:get()
            original_local = vim.opt_local.listchars:get()
            original_toggle = vim.g.u_list_chars_set
            original_list = vim.wo.list
            vim.opt_global.listchars = { lead = "⋅", tab = ">-", trail = "~" }
            vim.opt_local.listchars = { lead = "⋅", tab = ">-", trail = "~" }
            vim.wo.list = true
            vim.g.u_list_chars_set = true
            extra_windows, extra_buffers = {}, {}
            buffer = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "* item", "  continuation" })
            vim.api.nvim_win_set_buf(window, buffer)
            state.attach(buffer, { enable = true, hybrid_mode = false })
        end)

        after_each(function()
            callbacks.on_disable(buffer, { window })
            state.detach(buffer, true)
            for _, other in ipairs(extra_windows) do
                if vim.api.nvim_win_is_valid(other) then vim.api.nvim_win_close(other, true) end
            end
            vim.api.nvim_set_current_win(window)
            vim.api.nvim_win_set_buf(window, original_buffer)
            for _, other in ipairs(extra_buffers) do
                if vim.api.nvim_buf_is_valid(other) then vim.api.nvim_buf_delete(other, { force = true }) end
            end
            vim.api.nvim_buf_delete(buffer, { force = true })
            vim.opt_global.listchars = original_global
            vim.opt_local.listchars = original_local
            vim.wo.list = original_list
            vim.g.u_list_chars_set = original_toggle
        end)

        it("hides only lead in preview and preserves Markview's default conceal callback", function()
            callbacks.on_enable(buffer, { window })
            assert.is_nil(vim.opt_local.listchars:get().lead)
            assert.equals(">-", vim.opt_local.listchars:get().tab)
            assert.equals("~", vim.opt_local.listchars:get().trail)
            assert.equals("⋅", vim.opt_global.listchars:get().lead)
            assert.is_true(vim.wo.list)
            assert.equals(3, vim.wo.conceallevel)
        end)

        it("restores markers in Insert, Replace, and every Visual mode", function()
            for _, mode in ipairs({ "i", "R", "v", "V", "\22" }) do
                callbacks.on_mode_change(buffer, { window }, "n")
                assert.is_nil(vim.opt_local.listchars:get().lead)
                callbacks.on_mode_change(buffer, { window }, mode)
                assert.equals("⋅", vim.opt_local.listchars:get().lead)
                assert.equals(0, vim.wo.conceallevel)
            end
        end)

        it("restores custom markers on disable and detach without replacing other listchars", function()
            vim.opt_local.listchars:append({ lead = "+" })
            callbacks.on_enable(buffer, { window })
            vim.opt_local.listchars:append({ trail = "!" })
            callbacks.on_disable(buffer, { window })
            assert.equals("+", vim.opt_local.listchars:get().lead)
            assert.equals("!", vim.opt_local.listchars:get().trail)
            callbacks.on_enable(buffer, { window })
            callbacks.on_detach(buffer, { window })
            assert.equals("+", vim.opt_local.listchars:get().lead)
        end)

        it("restores markers when the window switches to a non-preview buffer", function()
            callbacks.on_enable(buffer, { window })
            local plain = vim.api.nvim_create_buf(false, true)
            table.insert(extra_buffers, plain)
            vim.api.nvim_win_set_buf(window, plain)
            assert.equals("⋅", vim.opt_local.listchars:get().lead)
            vim.api.nvim_win_set_buf(window, buffer)
            assert.is_nil(vim.opt_local.listchars:get().lead)
        end)

        it("synchronizes an existing preview when configuration is reloaded", function()
            assert.equals("⋅", vim.opt_local.listchars:get().lead)
            markview_mod.config()
            assert.is_nil(vim.opt_local.listchars:get().lead)
        end)

        it("handles inherited preview options in new splits without changing other windows", function()
            callbacks.on_enable(buffer, { window })
            local split = vim.api.nvim_open_win(buffer, true, { split = "right" })
            table.insert(extra_windows, split)
            assert.is_nil(vim.wo[split].listchars:match("lead:"))
            callbacks.on_mode_change(buffer, { split }, "i")
            assert.equals("⋅", vim.opt_local.listchars:get().lead)
            assert.is_nil(vim.wo[window].listchars:match("lead:"))
            callbacks.on_disable(buffer, { split })
        end)

        it("hides markers only in the dedicated split preview", function()
            local preview_buffer = vim.api.nvim_create_buf(false, true)
            table.insert(extra_buffers, preview_buffer)
            local preview_window = vim.api.nvim_open_win(preview_buffer, false, { split = "right" })
            table.insert(extra_windows, preview_window)
            callbacks.on_splitview_open(buffer, preview_buffer, preview_window)
            assert.is_nil(vim.wo[preview_window].listchars:match("lead:"))
            assert.equals("⋅", vim.opt_local.listchars:get().lead)
            callbacks.on_splitview_close(buffer, preview_buffer, preview_window)
            assert.is_not_nil(vim.wo[preview_window].listchars:match("lead:"))
        end)

        it("respects the existing manual leading-space toggle", function()
            callbacks.on_enable(buffer, { window })
            vim.g.u_list_chars_set = false
            callbacks.on_disable(buffer, { window })
            assert.is_nil(vim.opt_local.listchars:get().lead)
        end)
    end)
end)

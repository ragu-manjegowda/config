-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local M = {}

M.config = function()
    local ok, tso = pcall(require, "nvim-treesitter-textobjects")
    if not ok then
        vim.notify("nvim-treesitter-textobjects not found", vim.log.levels.ERROR)
        return
    end

    tso.setup({
        select = {
            lookahead = true,
        },
        move = {
            set_jumps = true,
        },
    })

    local select = require("nvim-treesitter-textobjects.select")
    local move = require("nvim-treesitter-textobjects.move")

    local function sel(query)
        return function() select.select_textobject(query, "textobjects") end
    end

    vim.keymap.set({ "x", "o" }, "af", sel("@function.outer"),
        { silent = true, desc = "TS: a function" })
    vim.keymap.set({ "x", "o" }, "if", sel("@function.inner"),
        { silent = true, desc = "TS: inner function" })
    vim.keymap.set({ "x", "o" }, "ac", sel("@class.outer"),
        { silent = true, desc = "TS: a class" })
    vim.keymap.set({ "x", "o" }, "ic", sel("@class.inner"),
        { silent = true, desc = "TS: inner class" })

    vim.keymap.set({ "n", "x", "o" }, "]m",
        function() move.goto_next_start("@function.outer", "textobjects") end,
        { silent = true, desc = "TS: next function start" })
    vim.keymap.set({ "n", "x", "o" }, "]c",
        function() move.goto_next_start("@class.outer", "textobjects") end,
        { silent = true, desc = "TS: next class start" })
    vim.keymap.set({ "n", "x", "o" }, "]M",
        function() move.goto_next_end("@function.outer", "textobjects") end,
        { silent = true, desc = "TS: next function end" })
    vim.keymap.set({ "n", "x", "o" }, "]C",
        function() move.goto_next_end("@class.outer", "textobjects") end,
        { silent = true, desc = "TS: next class end" })

    vim.keymap.set({ "n", "x", "o" }, "[m",
        function() move.goto_previous_start("@function.outer", "textobjects") end,
        { silent = true, desc = "TS: previous function start" })
    vim.keymap.set({ "n", "x", "o" }, "[c",
        function() move.goto_previous_start("@class.outer", "textobjects") end,
        { silent = true, desc = "TS: previous class start" })
    vim.keymap.set({ "n", "x", "o" }, "[M",
        function() move.goto_previous_end("@function.outer", "textobjects") end,
        { silent = true, desc = "TS: previous function end" })
    vim.keymap.set({ "n", "x", "o" }, "[C",
        function() move.goto_previous_end("@class.outer", "textobjects") end,
        { silent = true, desc = "TS: previous class end" })
end

return M

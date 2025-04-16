-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.before()
    vim.g.bazel_config = vim.g.bazel_config or ""

    -- If script is not sourced before opening vim, it won't be available
    vim.g.bazel_cmd = "dazel.py"
end

return M

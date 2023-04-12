-------------------------------------------------------------------------------
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-- reference    : https://github.com/alexander-born/nvim/blob/master/lua/plugins/bazel.lua
-------------------------------------------------------------------------------

local vim = vim

local M = {}

function M.before()
    vim.g.bazel_config = vim.g.bazel_config or ""

    vim.g.bazel_cmd = "dazel"

    vim.cmd([[
        set errorformat=ERROR:\ %f:%l:%c:%m
        set errorformat+=%f:%l:%c:%m
        set errorformat+=[\ \ FAILED\ \ ]\ %m\ (%.%#

        " Ignore build output lines starting with INFO:, Loading:, or [
        set errorformat+=%-GINFO:\ %.%#
        set errorformat+=%-GLoading:\ %.%#
        set errorformat+=%-G[%.%#

        " Errorformat settings
        " * errorformat reference: http://vimdoc.sourceforge.net/htmldoc/quickfix.html#errorformat
        " * look for message without consuming: https://stackoverflow.com/a/36959245/10923940
        " * errorformat explanation: https://stackoverflow.com/a/29102995/10923940

        " Ignore this error message, it is always redundant
        " ERROR: <filename>:<line>:<col>: C++ compilation of rule '<target>' failed (Exit 1)
        set errorformat+=%-GERROR:\ %f:%l:%c:\ C++\ compilation\ of\ rule\ %m
        set errorformat+=%tRROR:\ %f:%l:%c:\ %m   " Generic bazel error handler
        set errorformat+=%tARNING:\ %f:%l:%c:\ %m " Generic bazel warning handler
        " this rule is missing dependency declarations for the following files included by '<another-filename>'
        "   '<fname-1>'
        "   '<fname-2>'
        "   ...
        set errorformat+=%Ethis\ rule\ is\ %m\ the\ following\ files\ included\ by\ \'%f\':
        set errorformat+=%C\ \ \'%m\'
        set errorformat+=%Z

        " Test failures
        set errorformat+=FAIL:\ %m\ (see\ %f)            " FAIL: <test-target> (see <test-log>)

        " test failures in async builds
        set errorformat+=%E%*[\ ]FAILED\ in%m
        set errorformat+=%C\ \ %f
        set errorformat+=%Z

        " Errors in the build stage
        set errorformat+=%f:%l:%c:\ fatal\ %trror:\ %m         " <filename>:<line>:<col>: fatal error: <message>
        set errorformat+=%f:%l:%c:\ %trror:\ %m                " <filename>:<line>:<col>: error: <message>
        set errorformat+=%f:%l:%c:\ %tarning:\ %m              " <filename>:<line>:<col>: warning: <message>
        set errorformat+=%f:%l:%c:\ note:\ %m                  " <filename>:<line>:<col>: note: <message>
        set errorformat+=%f:%l:%c:\ \ \ requ%tred\ from\ here  " <filename>:<line>:<col>: <message>
        set errorformat+=%f(%l):\ %tarning:\ %m                " <filename>(<line>): warning: <message>
        set errorformat+=%f:%l:%c:\ %m                         " <filename>:<line>:<col>: <message>
        set errorformat+=%f:%l:\ %m                            " <filename>:<line>: <message>

        " command -nargs=* -complete=customlist,bazel#CompletionList Dazel
        "     \ call bazel#Run([<f-args>], {'executable': 'dazel.py'})
    ]])
end

-- Source bazel-complete.bash
-- vim.api.nvim_create_autocmd("UIEnter", {
--     pattern = { "*" },
--     command = "silent! source " ..
--         vim.fn.expand("~/.config/bash/bazel-complete.bash")
-- })

return M

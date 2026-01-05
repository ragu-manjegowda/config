-------------------------------------------------------------------------------
-- Test user/neovim-session-manager.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("SessionManager Config", function()
    local session_mod

    before_each(function()
        session_mod = require("user.neovim-session-manager")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(session_mod.config)
        end)
    end)
end)

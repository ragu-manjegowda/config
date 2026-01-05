-------------------------------------------------------------------------------
-- Test user/remote-nvim.lua configuration
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
-------------------------------------------------------------------------------

-- Suppress notifications during test
vim.notify = function(_, _, _) end
describe("RemoteNvim Config", function()
    local remote_mod

    before_each(function()
        remote_mod = require("user.remote-nvim")
    end)

    describe("Module Interface", function()
        it("should expose config function", function()
            assert.is_function(remote_mod.config)
        end)
    end)
end)

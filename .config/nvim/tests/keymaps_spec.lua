describe("Keymaps", function()
    local keymaps
    local original_execute
    local original_expand
    local original_get_current_line
    local original_os_uname
    local original_print
    local original_shellescape

    before_each(function()
        package.loaded["user.keymaps"] = nil
        keymaps = require("user.keymaps")
        original_execute = os.execute
        original_expand = vim.fn.expand
        original_get_current_line = vim.api.nvim_get_current_line
        original_os_uname = vim.uv.os_uname
        original_print = print
        original_shellescape = vim.fn.shellescape
    end)

    after_each(function()
        os.execute = original_execute
        vim.fn.expand = original_expand
        vim.api.nvim_get_current_line = original_get_current_line
        vim.uv.os_uname = original_os_uname
        print = original_print
        vim.fn.shellescape = original_shellescape
    end)

    local function image_open_command(sysname, exit_code)
        local callback
        keymaps.keymap = function(_, lhs, rhs)
            if lhs == "<leader>io" then
                callback = rhs
            end
        end
        keymaps.setup()

        local command
        local message
        vim.api.nvim_get_current_line = function()
            return "![image](figure.png)"
        end
        vim.fn.expand = function()
            return "/tmp"
        end
        vim.fn.shellescape = function(path)
            return path
        end
        vim.uv.os_uname = function()
            return { sysname = sysname }
        end
        os.execute = function(value)
            command = value
            return exit_code or 0
        end
        print = function(value)
            message = value
        end

        callback()
        return command, message
    end

    it("uses xdg-open for local images on Linux", function()
        assert.equals("xdg-open /tmp/figure.png", image_open_command("Linux"))
    end)

    it("uses open for local images on macOS", function()
        assert.equals("open /tmp/figure.png", image_open_command("Darwin"))
    end)

    it("reports a nonzero image opener exit code as failure", function()
        local _, message = image_open_command("Linux", 256)
        assert.equals("Failed to open image: /tmp/figure.png", message)
    end)
end)

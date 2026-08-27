local function read_file(path)
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
end

local source = read_file(os.getenv("HOME") .. "/.config/awesome/module/auto-start.lua")

local systemctl_bypass = source:match("if cmd:match%('%^systemctl%%s'%) then%s+awful%.spawn%.with_shell%(cmd%)%s+return%s+end")

if not systemctl_bypass then
    io.stderr:write("systemctl startup actions can be suppressed by pgrep deduplication\n")
    os.exit(1)
end

print("Systemctl startup actions bypass process-name deduplication")

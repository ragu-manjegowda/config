local function read_file(path)
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
end

local source = read_file(os.getenv("HOME") .. "/.config/awesome/module/auto-start.lua")

local systemctl_bypass = source:match("if cmd:match%('%^systemctl%%s'%) then%s+awful%.spawn%.with_shell%(cmd%)%s+return%s+end")
local nested_test_guard = source:match("os.getenv%('AWESOME_SKIP_AUTOSTART'%) == '1'") and
    source:match("if not auto_start_disabled then%s+for _, app in ipairs%(apps.run_on_start_up%) do") and
    source:match("if auto_start_disabled then return end")

if not systemctl_bypass then
    io.stderr:write("systemctl startup actions can be suppressed by pgrep deduplication\n")
    os.exit(1)
end

if not nested_test_guard then
    io.stderr:write("nested runtime tests cannot suppress desktop autostart side effects\n")
    os.exit(1)
end

print("Systemctl startup actions bypass process-name deduplication")
print("Nested runtime tests can suppress desktop autostart side effects")

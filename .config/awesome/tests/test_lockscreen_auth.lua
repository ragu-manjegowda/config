local tests_passed = 0
local tests_failed = 0

local function assert_test(condition, message, details)
    if condition then
        print("✓ " .. message)
        tests_passed = tests_passed + 1
    else
        print("✗ " .. message)
        if details then
            print("  " .. details)
        end
        tests_failed = tests_failed + 1
    end
end

local function read_file(path)
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
end

local source = read_file(os.getenv("HOME") .. "/.config/awesome/module/lockscreen.lua")

print("\nTest Suite: Lockscreen Authentication")

assert_test(
    source:match("local function authenticate_with_pam%(password%)") ~= nil,
    "PAM authentication is isolated in a helper"
)

assert_test(
    source:match("pcall%(function%(%)%s*return module:auth_current_user%(password%)%s*end%)") ~= nil,
    "PAM authentication is protected with pcall"
)

assert_test(
    source:match("if authenticated ~= nil then%s*return authenticated%s*end") ~= nil,
    "PAM false result returns before fallback password is checked"
)

assert_test(
    source:match("input_password == locker_config%.fallback_password%(%)") == nil,
    "Return-key path does not inline fallback password comparison"
)

assert_test(
    source:match("modifiers = { 'Mod1', 'Mod4', 'Shift', 'Control' }") ~= nil and
        source:match("key%s*=%s*'Return'") ~= nil and
        source:match("back_door%(%)") ~= nil,
    "Configured emergency backdoor chord is preserved"
)

assert_test(
    source:match("local ext_locker_arc = wibox%.widget") ~= nil and
        source:match("local ext_circle_container = wibox%.widget") ~= nil,
    "Secondary monitors render their own lock ring widgets"
)

assert_test(
    source:match("module::lockscreen_ring_feedback") ~= nil and
        source:match("module::lockscreen_auth_feedback") ~= nil,
    "Secondary monitor rings receive shared auth feedback signals"
)

assert_test(
    source:match("module::lockscreen_caps_state") ~= nil,
    "Secondary monitors receive Caps Lock state feedback"
)

assert_test(
    source:match("ontype%s*=") == nil and source:match("type = 'splash'") ~= nil,
    "Secondary lockscreen uses a valid wibox type"
)

assert_test(
    source:match("module::lockscreen_user_name") ~= nil and
        source:match("module::lockscreen_profile_image") ~= nil,
    "Secondary monitors mirror async username and profile image updates"
)

assert_test(
    source:match("module::lockscreen_ring_feedback', rotate_container%.direction, beautiful%.transparent") ~= nil,
    "Secondary monitor ring feedback clears on key release"
)

assert_test(
    source:match("circle_container%.bg = beautiful%.transparent%s+awesome%.emit_signal%('module::lockscreen_auth_feedback', beautiful%.transparent%)") ~= nil,
    "Secondary auth failure color resets when primary clears"
)

print("\n" .. string.rep("=", 50))
print(string.format("Results: %d passed, %d failed", tests_passed, tests_failed))

if tests_failed > 0 then
    os.exit(1)
end

os.exit(0)

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
local exit_source = read_file(os.getenv("HOME") .. "/.config/awesome/module/exit-screen.lua")
local battery_source = read_file(os.getenv("HOME") .. "/.config/awesome/widget/battery/init.lua")
local capture_source = read_file(os.getenv("HOME") .. "/.config/awesome/utilities/capture")

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
    source:match("local locked_media_signals =") ~= nil and
        source:match("XF86MonBrightnessUp = 'widget::brightness'") ~= nil and
        source:match("XF86MonBrightnessDown = 'widget::brightness'") ~= nil and
        source:match("XF86AudioRaiseVolume = 'widget::volume'") ~= nil and
        source:match("XF86AudioLowerVolume = 'widget::volume'") ~= nil and
        source:match("XF86AudioMute = 'widget::volume'") ~= nil and
        source:match("XF86AudioMicMute = 'widget::microphone'") ~= nil and
        source:match("module::mic_osd:show") ~= nil and
        source:match("if refresh_locked_media_osd%(key%) then") ~= nil,
    "Locked media keys refresh brightness and volume feedback"
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

assert_test(
    source:match("awesome%.disconnect_signal%(signal%[1%], signal%[2%]%)") ~= nil and
        source:match("screen%.disconnect_signal%('removed', removed_handler%)") ~= nil,
    "Secondary monitor signal handlers disconnect when their screen is removed"
)

assert_test(
    source:match("return s%.lockscreen or s%.lockscreen_extended") ~= nil and
        source:match("s%.lockscreen%.visible") == nil and
        source:match("s%.lockscreen_extended%.visible") == nil,
    "Lockscreen visibility tolerates a primary screen recreated with an extended decoration"
)

assert_test(
    source:match("local function ensure_password_grab%(%)") ~= nil and
        source:match("awful%.keygrabber%.current_instance == password_grabber") ~= nil and
        source:match("if not ensure_password_grab%(%) then") ~= nil and
        source:match("awesome%.emit_signal%('module::locked'%)") ~= nil,
    "Lock completion requires password keygrab ownership"
)

assert_test(
    source:match("module::sleep_resumed") ~= nil and
        source:match(
            "if is_lock_state_set%(%) then%s*ensure_password_grab%(%)%s*" ..
            "if fingerprint_auth then fingerprint_auth:start%(%) end%s*end"
        ) ~= nil and
        source:match("xset dpms force on") ~= nil,
    "Resume wakes DPMS and restores password and fingerprint authentication"
)

assert_test(
    source:match("lock_state_file") ~= nil and
        source:match("set_lock_state%(true%)") ~= nil and
        source:match("set_lock_state%(false%)") ~= nil and
        source:match("is_lock_state_set%(%)") ~= nil,
    "Lock state survives Awesome reload until authentication succeeds"
)

assert_test(
    exit_source:match("hibernate") == nil and
        exit_source:match("pending_sleep_action%s*=%s*'suspend'") ~= nil and
        exit_source:match("module::suspend") ~= nil and
        exit_source:match("module::locked") ~= nil,
    "Suspend waits for completed lockscreen keygrab setup"
)

assert_test(
    battery_source:match("module::suspend") ~= nil and
        battery_source:match("hibernate") == nil and
        source:match("elseif is_lock_state_set%(%) and ensure_password_grab%(%) then") ~= nil,
    "Critical battery suspend can confirm an already locked session"
)

assert_test(
    source:match("local capture_in_progress = false") ~= nil and
        source:match("if capture_in_progress then return end") ~= nil and
        source:match("reset_failed_auth%(%)") ~= nil and
        capture_source:match("timeout %-%-signal=TERM %-%-kill%-after=1 5") ~= nil,
    "Intruder capture cannot block failed-auth recovery indefinitely"
)

assert_test(
    source:match("require%('module%.lockscreen%-fingerprint'%)") ~= nil and
        source:match("on_match%s*=%s*function%(%)") ~= nil and
        source:match("generalkenobi_ohhellothere%(%)") ~= nil and
        source:match("on_no_match%s*=%s*function%(%)") ~= nil and
        source:match("stoprightthereyoucriminalscum%(%)") ~= nil,
    "Fingerprint match and failure use guarded lockscreen authentication paths"
)

assert_test(
    source:match("local ext_fingerprint_text%s*=%s*wibox%.widget") ~= nil and
        source:match("'module::lockscreen_fingerprint_text'") ~= nil and
        source:match("ext_fingerprint_text_widget,") ~= nil,
    "Fingerprint instructions appear and update on external lockscreens"
)

assert_test(
    source:match("local fingerprint_text_widget%s*=%s*wibox%.widget%s*{%s*bg%s*=%s*beautiful%.bg_normal") ~= nil and
        source:match("local ext_fingerprint_text_widget%s*=%s*wibox%.widget%s*{%s*bg%s*=%s*beautiful%.bg_normal") ~= nil,
    "Fingerprint instructions use a contrasting background on every screen"
)

assert_test(
    source:match("local function lockscreen_for_screen%(s%)") ~= nil and
        source:match("if not s%.valid then") ~= nil and
        source:match("if target == lockscreen_for_screen%(s%) then") ~= nil,
    "Wallpaper callbacks ignore removed or undecorated screens"
)

print("\n" .. string.rep("=", 50))
print(string.format("Results: %d passed, %d failed", tests_passed, tests_failed))

if tests_failed > 0 then
    os.exit(1)
end

os.exit(0)

local lifecycle = {}

function lifecycle.is_visible(screens)
    for s in screens do
        local target = s.lockscreen or s.lockscreen_extended
        if target and target.visible then return true end
    end
    return false
end

function lifecycle.owns_keygrab(current, expected)
    return current == expected
end

function lifecycle.can_show_intruder(exit_code, stdout, auth_succeeded, locked)
    return exit_code == 0 and stdout ~= nil and stdout ~= '' and not auth_succeeded and locked
end

function lifecycle.can_restart_fingerprint(locked, controller)
    return locked and controller ~= nil
end

return lifecycle

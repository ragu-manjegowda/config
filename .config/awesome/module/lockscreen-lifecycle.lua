local lifecycle = {}

function lifecycle.sync_geometry(s)
    local target = s.lockscreen or s.lockscreen_extended
    if not s.valid or not target then return false end
    target:geometry(s.geometry)
    return true
end

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

function lifecycle.hide_for_lock(focused, selected_tags)
    -- Prisma's fullscreen surface can remain transparent after an unmap/remap.
    -- Keep it mapped underneath the ontop lockscreen rather than forcing a
    -- fullscreen geometry change on unlock to make the browser paint again.
    local keep_mapped = focused and focused.valid and focused.fullscreen and
        (focused.class or ''):lower() == 'prisma-access-browser'
    if focused and focused.valid and not keep_mapped then
        focused.minimized = true
    end

    local previous_tag
    for _, t in ipairs(selected_tags) do
        previous_tag = t
        if not keep_mapped then t.selected = false end
    end
    return previous_tag
end

return lifecycle

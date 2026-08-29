-- Screen Manager Module
-- Handles graceful monitor connect/disconnect

local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')
local config = require('configuration.config')
local screen_tag_state = require('library.screen-tag-state')

local screen_manager = {}

-- Store window positions per screen
local window_state = {}

-- Track which clients were moved from external monitors
-- Format: { client = { tag_index = N, was_external = true } }
local external_clients = {}

-- Track last selected tag on external monitor
local last_external_tag_index = nil
local external_output = config.display.external.name
local restore_generation = 0
local primary_output = config.display.primary.name

local function is_external_screen(s)
    return s.valid and s.outputs and s.outputs[external_output] ~= nil
end

local function configured_primary_screen()
    for s in screen do
        if s.valid and s.outputs and s.outputs[primary_output] ~= nil then
            return s
        end
    end
    return nil
end

-- Save current window layout
local save_window_state = function()
    window_state = {}
    for c in awful.client.iterate(function() return true end) do
        table.insert(window_state, {
            client = c,
            screen = c.screen,
            tag = c.first_tag,
            floating = c.floating,
            maximized = c.maximized,
            geometry = c:geometry()
        })
    end
end

-- Reorganize windows when screen is removed
local reorganize_windows_on_remove = function(removed_screen)
    local primary_screen = configured_primary_screen()

    if not removed_screen.valid or not primary_screen then
        return
    end

    -- Move systray to primary screen when external is disconnected
    if primary_screen and primary_screen.systray then
        primary_screen.systray.screen = primary_screen
        primary_screen.systray.visible = true
    end

    -- Save the last selected tag on the external monitor before removal
    for _, tag in ipairs(removed_screen.tags) do
        if tag.selected then
            last_external_tag_index = tag.index
            break
        end
    end

    local clients = screen_tag_state.collect(removed_screen)
    local moved_count = 0
    local failed_count = 0

    for _, collected in ipairs(clients) do
        local c = collected.client
        local state = {
            tag_indices = collected.tag_indices,
            was_floating = c.floating,
            was_maximized = c.maximized,
            was_fullscreen = c.fullscreen,
            was_minimized = c.minimized,
            geometry = c:geometry(),
            source_geometry = {
                x = removed_screen.geometry.x,
                y = removed_screen.geometry.y,
                width = removed_screen.geometry.width,
                height = removed_screen.geometry.height
            }
        }
        external_clients[c] = state
        local target_tags = screen_tag_state.map(primary_screen, state.tag_indices)

        if not target_tags then
            failed_count = failed_count + 1
            naughty.notification({
                app_name = 'Screen Manager',
                title = 'Warning',
                message = 'Client tags were not found on the primary screen',
                timeout = 3
            })
        else
            local success = pcall(function()
                c:move_to_screen(primary_screen)
                c:tags(target_tags)

                if state.was_floating and state.geometry then
                    c:geometry(screen_tag_state.fit_geometry(
                        state.geometry, removed_screen.geometry, primary_screen.geometry))
                end
            end)

            if success then
                moved_count = moved_count + 1
            else
                failed_count = failed_count + 1
                naughty.notification({
                    app_name = 'Screen Manager',
                    title = 'Warning',
                    message = 'Failed to move window, but state is preserved for restore',
                    timeout = 3
                })
            end
        end
    end

    awful.layout.arrange(primary_screen)

    if moved_count > 0 then
        naughty.notification({
            app_name = 'Screen Manager',
            title = 'External Monitor Disconnected',
            message = moved_count .. ' window(s) saved. Will restore on reconnect.',
            timeout = 3
        })
    end

    return moved_count, failed_count
end

-- Restore windows to external monitor when reconnected
local restore_windows_to_external = function(new_screen)
    -- Move systray to external monitor
    if new_screen and new_screen.systray then
        new_screen.systray.screen = new_screen
        new_screen.systray.visible = true
    end

    local primary_screen = configured_primary_screen()
    local moved_count = 0
    local failed_count = 0
    local remaining = {}

        for c, state in pairs(external_clients) do
            if c.valid then
                local success = pcall(function()
                    local target_tags = screen_tag_state.map(new_screen, state.tag_indices)
                    assert(target_tags)
                    c:move_to_screen(new_screen)
                    c:tags(target_tags)

                    if state.was_minimized then
                        c.minimized = true
                    elseif state.was_fullscreen then
                        c.fullscreen = true
                    elseif state.was_maximized then
                        c.maximized = true
                    elseif state.was_floating and state.geometry then
                        c.floating = true
                        c:geometry(screen_tag_state.fit_geometry(
                            state.geometry, state.source_geometry, new_screen.geometry))
                    end

                    moved_count = moved_count + 1
                end)

                if not success then
                    failed_count = failed_count + 1
                    remaining[c] = state
                    naughty.notification({
                        app_name = 'Screen Manager',
                        title = 'Restore Failed',
                        message = 'Could not restore window: ' .. tostring(c.class or 'unknown'),
                        timeout = 3
                    })
                end
            end
        end

        external_clients = remaining

        -- Re-arrange windows on both screens
        awful.layout.arrange(new_screen)
        awful.layout.arrange(primary_screen)

        if moved_count > 0 then
            naughty.notification({
                app_name = 'Screen Manager',
                title = 'Windows Restored',
                message = moved_count .. ' window(s) moved back to external monitor',
                timeout = 3
            })
        end

        if failed_count > 0 then
            naughty.notification({
                app_name = 'Screen Manager',
                title = 'Restoration Complete',
                message = failed_count .. ' window(s) could not be restored',
                timeout = 3
            })
        end

        -- Restore focus to the last selected tag on external monitor
        -- Wait a bit longer to ensure all windows and tags are fully settled
        gears.timer.start_new(0.3, function()
            if is_external_screen(new_screen) and last_external_tag_index and
                new_screen.tags[last_external_tag_index] then
                new_screen.tags[last_external_tag_index]:view_only()
            end
            return false
        end)

    return moved_count, failed_count
end

-- Move all clients from primary to external monitor (fresh connect)
local move_all_clients_to_external = function(external_screen)
    local primary_screen = configured_primary_screen()
    if not primary_screen or primary_screen == external_screen then
        return 0, 1, 0
    end
    local moved_count = 0
    local failed_count = 0
    local original_states = {}

    -- Move systray to external monitor
    if external_screen and external_screen.systray then
        external_screen.systray.screen = external_screen
        external_screen.systray.visible = true
    end

    -- Get currently focused tag on primary screen
    local focused_tag_index = nil
    for _, tag in ipairs(primary_screen.tags) do
        if tag.selected then
            focused_tag_index = tag.index
            break
        end
    end

    for _, collected in ipairs(screen_tag_state.collect(primary_screen)) do
        local c = collected.client
        local target_tags = screen_tag_state.map(external_screen, collected.tag_indices)
        if c.valid and target_tags then
            local state = {
                client = c,
                tag_indices = collected.tag_indices,
                was_minimized = c.minimized,
                was_fullscreen = c.fullscreen,
                was_maximized = c.maximized,
                was_floating = c.floating,
                geometry = c:geometry()
            }
            original_states[#original_states + 1] = state
            local success = pcall(function()
                c:move_to_screen(external_screen)
                c:tags(target_tags)

                if state.was_minimized then
                    c.minimized = true
                elseif state.was_fullscreen then
                    c.fullscreen = true
                elseif state.was_maximized then
                    c.maximized = true
                elseif state.was_floating and state.geometry then
                    c.floating = true
                    c:geometry(screen_tag_state.fit_geometry(
                        state.geometry, primary_screen.geometry, external_screen.geometry))
                end
            end)
            if success then
                moved_count = moved_count + 1
            else
                failed_count = failed_count + 1
            end
        elseif c.valid then
            failed_count = failed_count + 1
        end
    end

    if failed_count > 0 then
        local rollback_failures = 0
        for _, state in ipairs(original_states) do
            local target_tags = screen_tag_state.map(primary_screen, state.tag_indices)
            local success = target_tags and pcall(function()
                state.client:move_to_screen(primary_screen)
                state.client:tags(target_tags)
                if state.was_minimized then
                    state.client.minimized = true
                elseif state.was_fullscreen then
                    state.client.fullscreen = true
                elseif state.was_maximized then
                    state.client.maximized = true
                elseif state.was_floating and state.geometry then
                    state.client.floating = true
                    state.client:geometry(state.geometry)
                end
            end)
            if not success then
                rollback_failures = rollback_failures + 1
            end
        end
        return 0, failed_count, rollback_failures
    end

    awful.layout.arrange(external_screen)
    awful.layout.arrange(primary_screen)

    -- Focus external screen and restore tag selection
    awful.screen.focus(external_screen)
    if focused_tag_index and external_screen.tags[focused_tag_index] then
        external_screen.tags[focused_tag_index]:view_only()
    end

    return moved_count, failed_count, 0
end

-- Handle screen being removed
-- Note: prepare_for_disconnect() already reorganizes windows BEFORE xrandr
-- removes the screen, so we guard against double-processing here.
screen.connect_signal(
    'removed',
    function(s)
        restore_generation = restore_generation + 1
        -- If prepare_for_disconnect already handled this screen,
        -- external_clients will have entries and the screen is now invalid.
        -- Only reorganize if there are clients still on this screen that
        -- were NOT already moved by prepare_for_disconnect.
        if s.valid and s ~= screen.primary then
            reorganize_windows_on_remove(s)
        end
    end
)

-- Handle screen being added
screen.connect_signal(
    'added',
    function(s)
        -- Only restore windows if this is NOT the initial startup
        -- and we actually have saved clients to restore
        if not awesome.startup and is_external_screen(s) and
            next(external_clients) ~= nil then
            restore_generation = restore_generation + 1
            local generation = restore_generation
            -- New screen detected
            naughty.notification({
                app_name = 'Screen Manager',
                title = 'External Monitor Connected',
                message = 'New display detected. Restoring windows...',
                timeout = 3
            })

            gears.timer.start_new(0.5, function()
                if generation == restore_generation and is_external_screen(s) then
                    restore_windows_to_external(s)
                end
                return false
            end)
        end
    end
)

screen_manager.prepare_for_disconnect = function()
    restore_generation = restore_generation + 1
    local primary_screen = configured_primary_screen()
    if not primary_screen then
        error('configured primary screen is not available')
    end
    local failed_count = 0
    for s in screen do
        if is_external_screen(s) then
            local _, failures = reorganize_windows_on_remove(s)
            failed_count = failed_count + failures
            if failures > 0 then
                local _, rollback_failures = restore_windows_to_external(s)
                if rollback_failures > 0 then
                    error('failed to roll back ' .. rollback_failures .. ' client(s)')
                end
            end
        end
    end
    if failed_count > 0 then
        error('failed to migrate ' .. failed_count .. ' client(s) to the primary screen')
    end
end

screen_manager.migrate_to_external = function()
    restore_generation = restore_generation + 1
    local external_screen = nil
    for s in screen do
        if is_external_screen(s) then
            external_screen = s
            break
        end
    end

    if external_screen then
        local moved, failures, rollback_failures =
            move_all_clients_to_external(external_screen)
        if rollback_failures > 0 then
            error('rollback failed for ' .. rollback_failures .. ' client(s)')
        end
        if failures > 0 then
            error('failed to migrate ' .. failures .. ' client(s) to the external screen')
        end
        if moved > 0 then
            naughty.notification({
                app_name = 'Screen Manager',
                title = 'Windows Migrated',
                message = moved .. ' window(s) moved to external monitor',
                timeout = 3
            })
        end
        return
    end
    error('configured external screen is not available')
end

screen_manager.restore_to_external = function()
    for s in screen do
        if is_external_screen(s) then
            local _, failures = restore_windows_to_external(s)
            if failures > 0 then
                error('failed to restore ' .. failures .. ' client(s) to the external screen')
            end
            return
        end
    end
    error('configured external screen is not available')
end

return screen_manager

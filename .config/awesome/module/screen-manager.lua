-- Screen Manager Module
-- Handles graceful monitor connect/disconnect

local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')

local screen_manager = {}

-- Store window positions per screen
local window_state = {}

-- Track which clients were moved from external monitors
-- Format: { client = { tag_index = N, was_external = true } }
local external_clients = {}

-- Track last selected tag on external monitor
local last_external_tag_index = nil

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
    local primary_screen = screen.primary

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

    -- Map clients by their tag index for better organization
    local clients_by_tag = {}
    local tags_to_show = {}

    -- Collect ALL clients from ALL tags on the removed screen
    for tag_idx, tag in ipairs(removed_screen.tags) do
        local tag_clients = tag:clients()

        for _, c in ipairs(tag_clients) do
            local tag_index = tag.index or 1

            if not clients_by_tag[tag_index] then
                clients_by_tag[tag_index] = {}
            end
            table.insert(clients_by_tag[tag_index], c)

            -- Save tag information BEFORE attempting to move
            -- This ensures we can restore even if move fails
            external_clients[c] = {
                tag_index = tag_index,
                tag_name = tag.name or tostring(tag_index),
                was_floating = c.floating,
                was_maximized = c.maximized,
                was_fullscreen = c.fullscreen,
                was_minimized = c.minimized,
                geometry = c:geometry()
            }

            -- Mark this tag as needing to be visible on primary screen
            tags_to_show[tag_index] = true
        end
    end

    -- Count total clients found
    local total_clients = 0
    for _, clients in pairs(clients_by_tag) do
        total_clients = total_clients + #clients
    end

    -- Ensure all needed tags are visible on primary screen
    for tag_index, _ in pairs(tags_to_show) do
        local target_tag = primary_screen.tags[tag_index]
        if target_tag and not target_tag.selected then
            -- Make tag visible (viewmore, not switch to it)
            target_tag.screen = primary_screen
            -- Don't select it, just make it available
            -- The tag will become visible when a window moves to it
        end
    end

    -- Move clients and try to preserve tag organization
    for tag_index, clients in pairs(clients_by_tag) do
        -- Get corresponding tag on primary screen
        local target_tag = primary_screen.tags[tag_index]

        if target_tag then
            for _, c in ipairs(clients) do
                -- Use pcall to catch any errors during move
                local success, err = pcall(function()
                    -- Move to primary screen FIRST
                    c:move_to_screen(primary_screen)

                    -- Clear existing tags
                    c:tags({})

                    -- Assign to target tag - this will make tag visible if it has clients
                    c:tags({ target_tag })

                    -- Toggle tag visibility if not already visible
                    if not target_tag.selected then
                        target_tag.selected = true
                    end

                    -- Preserve window state
                    if c.maximized then
                        c.maximized = true
                    elseif c.fullscreen then
                        c.fullscreen = true
                    elseif c.floating then
                        local geo = c:geometry()
                        -- Scale down if window is larger than new screen
                        if geo.width > primary_screen.geometry.width then
                            geo.width = primary_screen.geometry.width * 0.8
                        end
                        if geo.height > primary_screen.geometry.height then
                            geo.height = primary_screen.geometry.height * 0.8
                        end
                        -- Center on screen
                        geo.x = (primary_screen.geometry.width - geo.width) / 2
                        geo.y = (primary_screen.geometry.height - geo.height) / 2
                        c:geometry(geo)
                    end
                end)

                if not success then
                    -- If move failed, log it but keep the client info saved
                    naughty.notification({
                        app_name = 'Screen Manager',
                        title = 'Warning',
                        message = 'Failed to move window, but state is preserved for restore',
                        timeout = 3
                    })
                end
            end
        else
            -- If target tag doesn't exist, still keep client info for restoration
            naughty.notification({
                app_name = 'Screen Manager',
                title = 'Warning',
                message = 'Tag ' .. tag_index .. ' not found on primary, but will restore on reconnect',
                timeout = 3
            })
        end
    end

    -- Re-arrange tiled windows
    awful.layout.arrange(primary_screen)

    -- Focus the last selected tag on primary screen
    gears.timer.start_new(0.1, function()
        for _, tag in ipairs(primary_screen.tags) do
            if tag.selected then
                tag:view_only()
                break
            end
        end
        return false
    end)

    -- Only show notification if we actually moved windows
    if total_clients > 0 then
        naughty.notification({
            app_name = 'Screen Manager',
            title = 'External Monitor Disconnected',
            message = total_clients .. ' window(s) saved. Will restore on reconnect.',
            timeout = 3
        })
    end
end

-- Restore windows to external monitor when reconnected
local restore_windows_to_external = function(new_screen)
    -- Move systray to external monitor
    if new_screen and new_screen.systray then
        new_screen.systray.screen = new_screen
        new_screen.systray.visible = true
    end

    -- Wait a moment for screen to be fully initialized
    gears.timer.start_new(0.5, function()
        local primary_screen = screen.primary
        local moved_count = 0
        local failed_count = 0

        -- Find clients that were from external monitor
        for c, state in pairs(external_clients) do
            -- Check if client still exists (might be on any screen now)
            if c.valid then
                -- Use pcall to handle any errors during restoration
                local success, err = pcall(function()
                    -- Move back to external monitor
                    c:move_to_screen(new_screen)

                    -- Clear existing tags
                    c:tags({})

                    -- Restore to same tag index
                    local target_tag = new_screen.tags[state.tag_index]
                    if target_tag then
                        c:tags({ target_tag })
                        -- Make tag visible
                        if not target_tag.selected then
                            target_tag.selected = true
                        end
                    else
                        -- Fallback to tag 1 if original tag doesn't exist
                        c:tags({ new_screen.tags[1] })
                    end

                    -- Restore window state
                    if state.was_minimized then
                        c.minimized = true
                    elseif state.was_fullscreen then
                        c.fullscreen = true
                    elseif state.was_maximized then
                        c.maximized = true
                    elseif state.was_floating and state.geometry then
                        c.floating = true
                        -- Restore original geometry if it fits
                        local geo = state.geometry
                        if geo.width <= new_screen.geometry.width and
                           geo.height <= new_screen.geometry.height then
                            c:geometry(geo)
                        end
                    end

                    moved_count = moved_count + 1
                end)

                if not success then
                    failed_count = failed_count + 1
                    naughty.notification({
                        app_name = 'Screen Manager',
                        title = 'Restore Failed',
                        message = 'Could not restore window: ' .. tostring(c.class or 'unknown'),
                        timeout = 3
                    })
                end
            end
        end

        -- Clear the tracking table
        external_clients = {}

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
            if last_external_tag_index and new_screen.tags[last_external_tag_index] then
                new_screen.tags[last_external_tag_index]:view_only()
            end
            return false
        end)

        return false  -- Don't repeat timer
    end)
end

-- Move all clients from primary to external monitor (fresh connect)
local move_all_clients_to_external = function(external_screen)
    local primary_screen = screen.primary
    local clients_by_tag = {}
    local total_clients = 0

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

    -- Collect all clients from primary screen grouped by tag
    for _, tag in ipairs(primary_screen.tags) do
        local tag_clients = tag:clients()
        for _, c in ipairs(tag_clients) do
            if c.valid then
                local tag_index = tag.index or 1
                if not clients_by_tag[tag_index] then
                    clients_by_tag[tag_index] = {}
                end
                table.insert(clients_by_tag[tag_index], {
                    client = c,
                    was_floating = c.floating,
                    was_maximized = c.maximized,
                    was_fullscreen = c.fullscreen,
                    was_minimized = c.minimized,
                    geometry = c:geometry()
                })
                total_clients = total_clients + 1
            end
        end
    end

    -- Move clients to external screen, preserving tag assignments
    for tag_index, clients in pairs(clients_by_tag) do
        local target_tag = external_screen.tags[tag_index]
        if target_tag then
            for _, state in ipairs(clients) do
                local c = state.client
                pcall(function()
                    c:move_to_screen(external_screen)
                    c:tags({})
                    c:tags({ target_tag })

                    -- Restore window state
                    if state.was_minimized then
                        c.minimized = true
                    elseif state.was_fullscreen then
                        c.fullscreen = true
                    elseif state.was_maximized then
                        c.maximized = true
                    elseif state.was_floating and state.geometry then
                        c.floating = true
                        local geo = state.geometry
                        if geo.width <= external_screen.geometry.width and
                           geo.height <= external_screen.geometry.height then
                            c:geometry(geo)
                        end
                    end
                end)
            end
        end
    end

    awful.layout.arrange(external_screen)
    awful.layout.arrange(primary_screen)

    -- Focus external screen and restore tag selection
    awful.screen.focus(external_screen)
    if focused_tag_index and external_screen.tags[focused_tag_index] then
        external_screen.tags[focused_tag_index]:view_only()
    end

    return total_clients
end

-- Handle screen being removed
screen.connect_signal(
    'removed',
    function(s)
        if s ~= screen.primary then
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
        if not awesome.startup and next(external_clients) ~= nil then
            -- New screen detected
            naughty.notification({
                app_name = 'Screen Manager',
                title = 'External Monitor Connected',
                message = 'New display detected. Restoring windows...',
                timeout = 3
            })

            -- Restore windows that were previously on external monitor
            restore_windows_to_external(s)
        end
    end
)

screen_manager.prepare_for_disconnect = function()
    for s in screen do
        if s ~= screen.primary then
            reorganize_windows_on_remove(s)
        end
    end
end

screen_manager.migrate_to_external = function()
    local external_screen = nil
    for s in screen do
        if s ~= screen.primary then
            external_screen = s
            break
        end
    end

    if external_screen then
        local moved = move_all_clients_to_external(external_screen)
        if moved > 0 then
            naughty.notification({
                app_name = 'Screen Manager',
                title = 'Windows Migrated',
                message = moved .. ' window(s) moved to external monitor',
                timeout = 3
            })
        end
    end
end

return screen_manager


#!/usr/bin/env lua

local root = os.getenv('HOME') .. '/.config/awesome/'
local lifecycle = dofile(root .. 'library/notification-lifecycle.lua')

assert(lifecycle.is_ignored({ ignore = true }), 'ignored notification was not recognized')
assert(not lifecycle.is_ignored({ ignore = false }), 'visible notification was treated as ignored')
assert(not lifecycle.is_ignored({}), 'notification without an ignore flag was treated as ignored')

local sounded = setmetatable({}, { __mode = 'k' })
local visible = {}
assert(lifecycle.should_play_sound(visible, sounded, false),
    'new visible notification did not request a sound')
assert(not lifecycle.should_play_sound(visible, sounded, false),
    'resumed notification requested a duplicate sound')
local ignored = { ignore = true }
assert(not lifecycle.should_play_sound(ignored, sounded, false),
    'ignored notification requested a sound')
ignored.ignore = false
assert(not lifecycle.should_play_sound(ignored, sounded, false),
    'previously ignored notification sounded when resumed')
local muted = {}
assert(not lifecycle.should_play_sound(muted, sounded, true),
    'notification received during DND requested a sound')
assert(not lifecycle.should_play_sound(muted, sounded, false),
    'notification received during DND sounded when resumed')

local function notification(run)
    local handlers = {}
    local value = {
        run = run,
        destroy_count = 0,
    }

    function value:connect_signal(name, handler)
        handlers[name] = handler
    end

    function value:disconnect_signal(name, handler)
        if handlers[name] == handler then
            handlers[name] = nil
        end
    end

    function value:emit_signal(name)
        if handlers[name] then
            handlers[name]()
        end
    end

    function value:destroy(reason)
        self.destroy_count = self.destroy_count + 1
        self.destroy_reason = reason
        self:emit_signal('destroyed')
    end

    return value
end

local destroys_itself = notification(function(self)
    self:destroy(2)
end)
assert(lifecycle.invoke_default(destroys_itself, 2), 'default action was not invoked')
assert(destroys_itself.destroy_count == 1, 'self-destroying action was destroyed twice')

local leaves_open = notification(function() end)
assert(lifecycle.invoke_default(leaves_open, 2), 'non-destroying action was not invoked')
assert(leaves_open.destroy_count == 1, 'non-destroying action remained retained')
assert(leaves_open.destroy_reason == 2, 'fallback destroy reason changed')

local failing = notification(function()
    error('action failed')
end)
assert(lifecycle.invoke_default(failing, 2), 'failing action was not handled')
assert(failing.destroy_count == 1, 'failing action remained retained')
assert(not lifecycle.invoke_default(notification(nil), 2), 'missing action was reported as invoked')

local dbus_run_count = 0
local dbus_notification = notification(function()
    dbus_run_count = dbus_run_count + 1
end)
dbus_notification._private = { _unique_sender = ':1.23' }
assert(lifecycle.invoke_default(dbus_notification, 2), 'D-Bus default action was not invoked')
assert(dbus_run_count == 0, 'D-Bus default action was emitted directly and again on destroy')
assert(dbus_notification.destroy_count == 1, 'D-Bus notification was not dismissed exactly once')

local suspended = notification(nil)
local suspension_count = 0
local handler = lifecycle.watch_suspension(suspended, function()
    suspension_count = suspension_count + 1
end)
suspended.suspended = false
suspended:emit_signal('property::suspended')
suspended.suspended = true
suspended:emit_signal('property::suspended')
assert(suspension_count == 1, 'suspension callback did not filter resumed state')
suspended:disconnect_signal('property::suspended', handler)
suspended:emit_signal('property::suspended')
assert(suspension_count == 1, 'suspension callback did not disconnect')

local controller = assert(io.open(root .. 'module/notifications.lua', 'r'))
local source = controller:read('*a')
controller:close()
assert(source:match('notification_store:get%(n%) or track_notification%(n%)'),
    'display path does not track before rendering')
assert(source:match('if not entry or next%(entry%.cards%) then'),
    'self-evicted notifications can still render')
assert(source:match('if lifecycle%.is_ignored%(n%) then%s+n:destroy'),
    'ignored notifications are retained in naughty.active')

local views = assert(io.open(root .. 'widget/notif-center/build-notifbox/init.lua', 'r'))
local view_source = views:read('*a')
views:close()
assert(view_source:match('if removed_cards%[card%] then%s+return'),
    'card removal is not idempotent')
assert(source:match("widget::notif%-center:view_added"),
    'new notification views are not hydrated')
assert(source:match("widget::notif%-center:view_removed"),
    'removed notification views retain card mappings')
assert(source:match('notif_manager%.clear_all%(%)'),
    'clear-all does not reset stale notification cards')
assert(source:match('if c and c%.valid and c%.urgent then%s+c:jump_to%(%s*%)'),
    'clicked notifications do not raise the next urgent client')
assert(not source:match('names%[c%.name%]'),
    'urgent client focus still depends on a mutable window title')
assert(view_source:match('function manager%.clear_all%('),
    'notification view manager cannot reset all views')
assert(view_source:match(
    'local function show_empty_state%(%)%s+view%.remove_notifbox_empty = true%s+view%.notifbox_layout:reset%(%s*%)'),
    'empty placeholder is counted before its state flag is updated')

local keys = assert(io.open(root .. 'configuration/keys/global.lua', 'r'))
local key_source = keys:read('*a')
keys:close()
assert(not key_source:match('naughty%.destroy_all_notifications'),
    'popup dismissal still destroys retained notifications')
assert(key_source:match("awesome%.emit_signal%('module::notifications:dismiss_popup'%)"),
    'popup dismissal shortcut does not use the scoped notification signal')
assert(source:match("awesome%.connect_signal%('module::notifications:dismiss_popup'"),
    'notification controller does not handle scoped popup dismissal')
assert(source:match('for index = #popup_order, 1, %-1 do') and
        source:match('local notification = popup_order%[index%]') and
        source:match('notification:destroy%(cst%.notification_closed_reason%.silent%)'),
    'popup dismissal does not destroy every visible popup')
assert(key_source:match(
    "if focused%.info_center and focused%.info_center%.visible then%s+awesome%.emit_signal%('widget::notif%-center:clear_all'%)"),
    'clear shortcut no longer requires an open Info Center')

local sound = assert(io.open(root .. 'widget/dont-disturb/init.lua', 'r'))
local sound_source = sound:read('*a')
sound:close()
assert(sound_source:match('lifecycle%.should_play_sound%('),
    'notification sound is not guarded against ignored or resumed notifications')
assert(sound_source:match("naughty%.connect_signal%(%s*'property::active'"),
    'notification sound is deferred until suspended notifications resume')
assert(not sound_source:match("naughty%.connect_signal%(%s*'request::display'%s*,%s*function%(n%)"),
    'notification sound still follows popup replay instead of notification creation')

print('Notification lifecycle tests passed')

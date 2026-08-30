local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local config = require('configuration.config')
local recorder_scripts = require('widget.screen-recorder.screen-recorder-scripts')
local recorder_state = require('widget.screen-recorder.screen-recorder-state')
local recorder_source = require('widget.screen-recorder.screen-recorder-source')
local recorder_selector = require('widget.screen-recorder.screen-recorder-selector')
local recorder_settings = require('widget.screen-recorder.screen-recorder-settings')
local recorder_icons = require('widget.screen-recorder.screen-recorder-icons')
local recorder_notification = require('widget.screen-recorder.screen-recorder-notification')
local recorder_ui = require('widget.screen-recorder.screen-recorder-ui')

local source_controller = recorder_source.new(config)
local capture_state = source_controller.state

local toggle_imgbox = recorder_ui.screen_rec_toggle_imgbox
local toggle_button = recorder_ui.screen_rec_toggle_button
local countdown_text = recorder_ui.screen_rec_countdown_txt
local main_imgbox = recorder_ui.screen_rec_main_imgbox
local main_button = recorder_ui.screen_rec_main_button
local audio_imgbox = recorder_ui.screen_rec_audio_imgbox
local audio_button = recorder_ui.screen_rec_audio_button
local settings_button = recorder_ui.screen_rec_settings_button
local close_button = recorder_ui.screen_rec_close_button
local back_button = recorder_ui.screen_rec_back_button
local source_buttons = recorder_ui.screen_rec_source_buttons
local area_tbox = recorder_ui.screen_rec_area_txtbox:get_children_by_id('area_tbox')[1]
local source_keys = recorder_ui.screen_rec_area_hint:get_children_by_id('source_keys_tbox')[1]
local cancel_hint = recorder_ui.screen_rec_area_hint:get_children_by_id('cancel_hint_tbox')[1]

local active_screen, pending_geometry, countdown_timer = nil, nil, nil
local status_countdown, status_recording, status_audio = false, false, capture_state.audio
local navigation_reset, settings_controller, countdown_stop

local function notification(title, message)
    naughty.notification({
        app_name = 'Screen Recorder',
        title = title,
        message = message,
        timeout = 5
    })
end

local function persist_state()
    local success, err = source_controller:save()
    if not success then
        notification('Settings were not saved', tostring(err))
    end
end

local function update_audio_icon()
    local icon = status_audio and 'audio' or 'audio-mute'
    audio_imgbox:set_image(recorder_icons.normal(icon))
end

local function show_settings(recorder_screen)
    if not recorder_screen or not recorder_screen.valid then
        recorder_screen = awful.screen.focused().recorder_screen
    end
    if not recorder_screen or not recorder_screen.valid then
        return
    end
    local panel = recorder_screen:get_children_by_id('recorder_panel')[1]
    local settings = recorder_screen:get_children_by_id('recorder_settings')[1]
    panel.visible = false
    settings.visible = true
    recorder_screen.visible = true
    active_screen = recorder_screen
    settings_controller:refresh()
    settings_controller:start()
end

local function select_area()
    if status_recording or status_countdown or recorder_selector.active then
        return
    end
    local origin = active_screen
    settings_controller:stop()
    settings_controller:refresh('Drag to select; right-click to cancel')
    recorder_selector.start(function()
        for s in screen do
            if s.recorder_screen then
                s.recorder_screen.visible = false
            end
        end
    end, function(region, reason)
        if region then
            capture_state.source = 'region'
            capture_state.region = region
            persist_state()
        elseif reason == 'invalid' then
            notification('Area not selected', 'Select an area at least 16x16 pixels.')
        end
        show_settings(origin)
    end)
end

settings_controller = recorder_settings.new {
    source_controller = source_controller,
    buttons = source_buttons,
    area = area_tbox,
    source_hint = source_keys,
    cancel_hint = cancel_hint,
    dpi = dpi,
    accent = beautiful.accent,
    transparent = beautiful.transparent,
    summary = recorder_state.summary,
    can_update = function()
        return not status_recording and not status_countdown and not recorder_selector.active
    end,
    on_select_area = select_area,
    on_escape = function() navigation_reset() end,
    on_error = notification
}

navigation_reset = function()
    if not active_screen then
        return
    end
    settings_controller:stop()
    active_screen:get_children_by_id('recorder_settings')[1].visible = false
    active_screen:get_children_by_id('recorder_panel')[1].visible = true
end

local function close_recorder()
    if status_countdown then countdown_stop() end
    for s in screen do
        if s.recorder_screen then
            s.recorder_screen.visible = false
        end
    end
    navigation_reset()
    active_screen = nil
end

local function toggle_settings()
    if not active_screen then
        return
    end
    local panel = active_screen:get_children_by_id('recorder_panel')[1]
    if panel.visible then
        show_settings(active_screen)
    else
        navigation_reset()
    end
end

local function audio_mode()
    if status_recording or status_countdown then
        return
    end
    status_audio = not status_audio
    capture_state.audio = status_audio
    persist_state()
    update_audio_icon()
end

local function same_geometry(first, second)
    return first and second and first.x == second.x and first.y == second.y and
        first.width == second.width and first.height == second.height
end

local function recording_start()
    status_countdown = false
    countdown_text.opacity = 0
    countdown_text:emit_signal('widget::redraw_needed')
    local geometry, err = source_controller:resolve()
    if not geometry or not same_geometry(geometry, pending_geometry) then
        main_imgbox:set_image(recorder_icons.normal('recorder-off'))
        countdown_text.opacity = 0
        notification('Recording cancelled', err or 'Capture source changed during countdown.')
        return
    end
    local pid, start_error = recorder_scripts.start_recording(
        status_audio, geometry, function(success, filename, finish_error)
            status_recording = false
            toggle_imgbox:set_image(recorder_icons.normal('start-recording-button'))
            main_imgbox:set_image(recorder_icons.normal('recorder-off'))
            if success then
                recorder_notification.finished(filename)
            else
                notification('Recording failed', finish_error)
            end
        end)
    if not pid then
        main_imgbox:set_image(recorder_icons.normal('recorder-off'))
        notification('Recording failed', start_error)
        return
    end
    status_recording = true
    if active_screen then
        active_screen.visible = false
    end
    toggle_imgbox:set_image(recorder_icons.urgent('recording-button'))
    main_imgbox:set_image(recorder_icons.urgent('recorder-on'))
end

local function recording_stop()
    if not recorder_scripts.stop_recording() then
        status_recording = false
        toggle_imgbox:set_image(recorder_icons.normal('start-recording-button'))
        main_imgbox:set_image(recorder_icons.normal('recorder-off'))
        notification('Recording stopped', 'The FFmpeg process was no longer running.')
    end
end

local function countdown_start()
    local geometry, err = source_controller:resolve()
    if not geometry then
        notification('Recording unavailable', err)
        return
    end
    pending_geometry = geometry
    status_countdown = true
    local seconds = 3
    countdown_timer = gears.timer.start_new(1, function()
        if seconds == 0 then
            recording_start()
            countdown_text:emit_signal('widget::redraw_needed')
            return false
        end
        main_imgbox:set_image(recorder_icons.accent('recorder-countdown'))
        countdown_text.opacity = 1
        countdown_text:set_text(tostring(seconds))
        countdown_text:emit_signal('widget::redraw_needed')
        seconds = seconds - 1
        return true
    end)
end

countdown_stop = function()
    if countdown_timer then
        countdown_timer:stop()
    end
    status_countdown = false
    main_imgbox:set_image(recorder_icons.normal('recorder-off'))
    countdown_text.opacity = 0
end

settings_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
    if not status_recording and not status_countdown then toggle_settings() end
end)))
back_button:buttons(gears.table.join(awful.button({}, 1, nil, navigation_reset)))
close_button:buttons(gears.table.join(awful.button({}, 1, nil, close_recorder)))
audio_button:buttons(gears.table.join(awful.button({}, 1, nil, audio_mode)))
main_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
    if status_recording and not status_countdown then
        recording_stop()
    elseif status_countdown then
        countdown_stop()
    else
        countdown_start()
    end
end)))

toggle_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
    for s in screen do
        if s.recorder_screen then s.recorder_screen.visible = false end
    end
    active_screen = awful.screen.focused().recorder_screen
    navigation_reset()
    active_screen.visible = true
    settings_controller:refresh()
end)))

update_audio_icon()

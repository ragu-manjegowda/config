local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require('widget.clickable-container')
local icons = require('theme.icons')
local audio_monitor = require('library.audio-monitor')
local display_audio = require('library.display-audio')

local mic_muted = false
local mic_available = false
local refresh_generation = 0

local action_name = wibox.widget {
    text = 'Microphone',
    font = beautiful.font_bold(11),
    align = 'left',
    widget = wibox.widget.textbox
}

local action_status = wibox.widget {
    text = 'On',
    font = beautiful.font_regular(10),
    align = 'left',
    widget = wibox.widget.textbox
}

local action_info = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    action_name,
    action_status
}

local button_widget = wibox.widget {
    {
        id = 'icon',
        image = icons.microphone_high,
        widget = wibox.widget.imagebox,
        resize = true
    },
    layout = wibox.layout.align.horizontal
}

local widget_button = wibox.widget {
    {
        {
            button_widget,
            margins = dpi(15),
            forced_height = dpi(48),
            forced_width = dpi(48),
            widget = wibox.container.margin
        },
        widget = clickable_container
    },
    bg = beautiful.background,
    shape = gears.shape.circle,
    widget = wibox.container.background
}

local update_widget = function()
    if not mic_available then
        action_status:set_text('Unavailable')
        widget_button.bg = beautiful.background
        button_widget.icon:set_image(icons.microphone_muted)
    elseif mic_muted then
        action_status:set_text('Muted')
        widget_button.bg = beautiful.background
        button_widget.icon:set_image(icons.microphone_muted)
    else
        action_status:set_text('On')
        widget_button.bg = beautiful.accent
        button_widget.icon:set_image(icons.microphone_high)
    end
end

local function apply_state(state, output)
    mic_available, mic_muted = state.available, state.muted or false
    action_name:set_text(display_audio.scope(output) == 'external' and 'Monitor Mic' or 'Microphone')
    update_widget()
    awesome.emit_signal('module::mic_osd:update', mic_muted, output, mic_available)
end

local check_mic_status = function()
    refresh_generation = refresh_generation + 1
    local generation, output = refresh_generation, display_audio.output()
    display_audio.read(output, 'source', function(state)
        if generation ~= refresh_generation or output ~= display_audio.output() or display_audio.pending(output, 'source') then return end
        apply_state(state, output)
    end)
end

check_mic_status()

local toggle_mic = function()
    refresh_generation = refresh_generation + 1
    display_audio.toggle('source')
end

widget_button:buttons(
    gears.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                toggle_mic()
            end
        )
    )
)

action_info:buttons(
    gears.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                toggle_mic()
            end
        )
    )
)

local action_widget = wibox.widget {
    layout = wibox.layout.fixed.horizontal,
    spacing = dpi(10),
    widget_button,
    {
        layout = wibox.layout.align.vertical,
        expand = 'none',
        nil,
        action_info,
        nil
    }
}

audio_monitor:connect_signal('source', check_mic_status)
awesome.connect_signal('control_center::visibility', function(visible)
    if visible then check_mic_status() end
end)
action_widget:connect_signal('mouse::enter', check_mic_status)
awesome.connect_signal('widget::audio:changed', function(output, kind, state)
    if kind == 'source' and output == display_audio.output() and not display_audio.pending(output, kind) then
        refresh_generation = refresh_generation + 1
        apply_state(state, output)
    end
end)

-- Subscribe to global mic OSD updates
awesome.connect_signal(
    'widget::microphone',
    function()
        check_mic_status()
    end
)

return action_widget

local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local display_audio = require('library.display-audio')
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')
local clickable_container = require('widget.clickable-container')
local slider_hover = require('widget.slider-hover')
local audio_monitor = require('library.audio-monitor')

local action_name = wibox.widget {
    text = 'Volume',
    font = beautiful.font_bold(12),
    align = 'left',
    widget = wibox.widget.textbox
}

local volume_icon = wibox.widget {
    image = icons.volume_muted,
    resize = true,
    widget = wibox.widget.imagebox
}

local icon = wibox.widget {
    layout = wibox.layout.align.vertical,
    expand = 'none',
    nil,
    volume_icon,
    nil
}

local action_level = wibox.widget {
    {
        {
            icon,
            margins = dpi(5),
            widget = wibox.container.margin
        },
        widget = clickable_container,
    },
    bg = beautiful.groups_bg,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
    end,
    widget = wibox.container.background
}

local slider = wibox.widget {
    nil,
    {
        id                  = 'volume_slider',
        bar_shape           = gears.shape.rounded_rect,
        bar_height          = dpi(24),
        bar_color           = beautiful.background,
        bar_active_color    = beautiful.accent,
        handle_color        = beautiful.accent,
        handle_shape        = gears.shape.circle,
        handle_width        = dpi(24),
        handle_border_color = beautiful.background,
        handle_border_width = dpi(1),
        maximum             = 100,
        widget              = wibox.widget.slider
    },
    nil,
    expand = 'none',
    forced_height = dpi(24),
    layout = wibox.layout.align.vertical
}

local volume_slider = slider.volume_slider
slider_hover.attach(volume_slider)

-- Track if we're updating the slider programmatically (from event monitor)
local is_programmatic_update = false
local refresh_generation = 0
local current_state = { available = false }

volume_slider:connect_signal(
    'property::value',
    function()
        -- Skip if this is an automatic update from the event monitor
        if is_programmatic_update then
            return
        end

        local volume_level = volume_slider:get_value()
        refresh_generation = refresh_generation + 1
        local output = display_audio.output()
        display_audio.set(output, volume_level)

        -- Show volume osd
        awesome.emit_signal(
            'module::volume_osd:show',
            true
        )

        -- Update the OSD slider value
        awesome.emit_signal(
            'module::volume_osd',
            volume_level,
            output
        )
    end
)

local function apply_state(state, output)
    current_state = state
    action_name:set_text(display_audio.scope(output) == 'external' and 'Monitor Volume' or 'Volume')
    if not state.available then action_name:set_text(action_name.text .. ' — unavailable') end
    is_programmatic_update = true
    volume_slider:set_value(state.available and math.min(100, state.volume) or 0)
    is_programmatic_update = false
    volume_icon:set_image(state.available and not state.muted and icons.volume or icons.volume_muted)
    awesome.emit_signal('module::volume_osd:update_icon', not state.available or state.muted, output)
    awesome.emit_signal('module::volume_osd', state.available and state.volume or 0, output)
end

local update_slider = function(show_osd)
    refresh_generation = refresh_generation + 1
    local generation, output = refresh_generation, display_audio.output()
    display_audio.read(output, 'sink', function(state)
        if generation ~= refresh_generation or output ~= display_audio.output() or display_audio.pending(output, 'sink') then return end
        apply_state(state, output)
        if show_osd and state.available then awesome.emit_signal('module::volume_osd:show', true) end
    end)
end

-- Update on startup
update_slider()

local action_jump = function()
    local sli_value = volume_slider:get_value()
    local new_value

    if sli_value >= 0 and sli_value < 50 then
        new_value = 50
    elseif sli_value >= 50 and sli_value < 100 then
        new_value = 100
    else
        new_value = 0
    end
    volume_slider:set_value(new_value)
end

action_level:buttons(
    awful.util.table.join(
        awful.button(
            {},
            1,
            nil,
            function()
                action_jump()
            end
        )
    )
)

-- The emit will come from the global keybind
awesome.connect_signal(
    'widget::volume',
    function(show_osd)
        update_slider(show_osd)
    end
)

-- The emit will come from the OSD
awesome.connect_signal(
    'widget::volume:update',
    function(value, output)
        if output and output ~= display_audio.output() then return end
        is_programmatic_update = true
        volume_slider:set_value(tonumber(value))
        is_programmatic_update = false
    end
)

audio_monitor:connect_signal('sink', function()
    update_slider(false)
end)

awesome.connect_signal('widget::audio:changed', function(output, kind, state)
    if kind == 'sink' and output == display_audio.output() and not display_audio.pending(output, kind) then
        refresh_generation = refresh_generation + 1
        apply_state(state, output)
    end
end)
awesome.connect_signal('control_center::visibility', function(visible)
    if visible then update_slider(false) end
end)

local volume_setting = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    forced_height = dpi(48),
    spacing = dpi(5),
    action_name,
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(5),
        {
            layout = wibox.layout.align.vertical,
            expand = 'none',
            nil,
            {
                layout = wibox.layout.fixed.horizontal,
                forced_height = dpi(24),
                forced_width = dpi(24),
                action_level
            },
            nil
        },
        slider
    }
}

local myvolumemeter_t = awful.tooltip {}

myvolumemeter_t:add_to_object(volume_setting)

volume_setting:connect_signal('mouse::enter', function()
    update_slider(false)
    myvolumemeter_t.text = current_state.description or 'Audio status unavailable'
end)

return volume_setting

local top_panel = require('layout.top-panel')
local control_center = require('layout.control-center')
local info_center = require('layout.info-center')
local calendar_center = require('layout.calendar-center')
local playerctl_center = require('layout.playerctl-center')

-- Create a wibox panel for each screen and add it
screen.connect_signal(
    'request::desktop_decoration',
    function(s)
        s.top_panel = top_panel(s)
        s.control_center = control_center(s)
        s.info_center = info_center(s)
        s.calendar_center = calendar_center(s)
        s.playerctl_center = playerctl_center(s)
        s.control_center_show_again = false
        s.info_center_show_again = false
        s.calendar_center_show_again = false
        s.playerctl_center_show_again = false
    end
)

-- Hide bars when app go fullscreen
function UPDATE_BARS_VISIBILITY()
    for s in screen do
        if s.selected_tag then
            local fullscreen = s.selected_tag.fullscreen_mode
            -- Order matter here for shadow
            s.top_panel.visible = not fullscreen
            if s.control_center then
                if fullscreen and s.control_center.visible then
                    s.control_center:toggle()
                    s.control_center_show_again = true
                elseif not fullscreen and not s.control_center.visible and s.control_center_show_again then
                    s.control_center:toggle()
                    s.control_center_show_again = false
                end
            end
            if s.info_center then
                if fullscreen and s.info_center.visible then
                    s.info_center:toggle()
                    s.info_center_show_again = true
                elseif not fullscreen and not s.info_center.visible and s.info_center_show_again then
                    s.info_center:toggle()
                    s.info_center_show_again = false
                end
            end
            if s.calendar_center then
                if fullscreen and s.calendar_center.visible then
                    s.calendar_center:toggle()
                    s.calendar_center_show_again = true
                elseif not fullscreen and not s.calendar_center.visible and s.calendar_center_show_again then
                    s.calendar_center:toggle()
                    s.calendar_center_show_again = false
                end
            end
            if s.playerctl_center then
                if fullscreen and s.playerctl_center.visible then
                    s.playerctl_center:toggle()
                    s.playerctl_center_show_again = true
                elseif not fullscreen and not s.playerctl_center.visible and s.playerctl_center_show_again then
                    s.playerctl_center:toggle()
                    s.playerctl_center_show_again = false
                end
            end
        end
    end
end

tag.connect_signal(
    'property::selected',
    function(_)
        UPDATE_BARS_VISIBILITY()
    end
)

client.connect_signal(
    'property::fullscreen',
    function(c)
        if c.first_tag then
            c.first_tag.fullscreen_mode = c.fullscreen
        end
        UPDATE_BARS_VISIBILITY()
    end
)

client.connect_signal(
    'unmanage',
    function(c)
        if c.fullscreen then
            c.screen.selected_tag.fullscreen_mode = false
            UPDATE_BARS_VISIBILITY()
        end
    end
)

local awful = require("awful")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local gears = require("gears")
local wibox = require("wibox")
local rubato = require("library.rubato")

local function get_taglist(s)
    local screen_for_taglist = s or awful.screen.focused()

    -- Function to update the tags
    local update_tags = function(self, c3)
        self:get_children_by_id("tag_id")[1].image = c3.icon
        if c3.selected then
            self:get_children_by_id("indicator_id")[1].bg = beautiful.taglist_bg_focus
            self.anim.target = 34
        else
            -- this can also be s.clients if only visible client needs to be included
            for _, c in ipairs(screen_for_taglist.all_clients) do
                for _, t in ipairs(c:tags()) do
                    if c3 == t and c.urgent then
                        self:get_children_by_id("indicator_id")[1].bg = beautiful.taglist_bg_urgent
                        self.anim.target = 34
                        return
                    elseif c3 == t then
                        self:get_children_by_id("indicator_id")[1].bg = beautiful.taglist_bg_occupied
                        self.anim.target = 25
                        return
                    end
                end
            end

            self:get_children_by_id("indicator_id")[1].bg = beautiful.taglist_bg_empty
            self.anim.target = 8
        end
    end

    local taglist = awful.widget.taglist({
        screen = screen_for_taglist,
        filter = awful.widget.taglist.filter.all,
        layout = { spacing = dpi(10), layout = wibox.layout.fixed.horizontal },
        widget_template = {
            valign = "center",
            {
                id = 'indicator_id',
                {
                    {
                        {
                            id = 'tag_id',
                            widget = wibox.widget.imagebox,
                        },
                        layout = wibox.layout.fixed.horizontal,
                    },
                    margins = 2,
                    widget  = wibox.container.margin,
                },
                shape = gears.shape.rounded_rect,
                widget = wibox.container.background,
            },
            id = "place_id",
            widget = wibox.container.place,
            create_callback = function(self, c3, _, _)
                self.anim = rubato.timed {
                    intro = 0,
                    outro = 0.9,
                    duration = 2,
                    easing = rubato.bouncy,
                    subscribed = function(width)
                        self:get_children_by_id("tag_id")[1].forced_width =
                            dpi(width)
                    end
                }

                update_tags(self, c3)
            end,
            update_callback = function(self, c3, _, _)
                update_tags(self, c3)
            end
        }
    })

    return {
        taglist,
        widget = wibox.container.margin
    }
end

return get_taglist

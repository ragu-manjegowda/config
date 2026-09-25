local home = assert(os.getenv('HOME'))
package.path = home .. '/.config/awesome/?.lua;' .. package.path

local function widget(args)
    local instance = { value = args }
    local signals = {}
    function instance:connect_signal(name, handler)
        signals[name] = handler
    end
    function instance:emit_signal(name)
        if signals[name] then signals[name]() end
    end
    function instance:buttons(buttons)
        self.clicks = buttons
    end
    function instance:set_markup(markup)
        self.markup = markup
    end
    return instance
end

package.loaded.wibox = {
    widget = setmetatable({ textbox = 'textbox' }, { __call = function(_, args) return widget(args) end }),
    layout = { fixed = { vertical = 'vertical', horizontal = 'horizontal' },
        align = { horizontal = 'horizontal' } },
    container = { margin = 'margin', background = 'background' },
}
local toggles = 0
local focused = { valid = true, info_center = { visible = true } }
function focused.info_center:toggle() toggles = toggles + 1 end
local raised = 0
local clients = { { class = 'Other App' }, { class = 'Example Browser' } }
clients[2].jump_to = function() raised = raised + 1 end
client = { get = function() return clients end }
package.loaded.awful = {
    button = function(_, number, press, release)
        return { number = number, callback = press or release }
    end,
    util = { table = { join = function(...) return { ... } end } },
    screen = { focused = function() return focused end },
}
package.loaded.gears = {
    shape = { rounded_rect = function() end },
    timer = function()
        return {
            started = false,
            start = function(self) self.started = true end,
            stop = function(self) self.started = false end,
        }
    end,
}
package.loaded.beautiful = {
    xresources = { apply_dpi = function(value) return value end },
    font_regular = function() return 'font' end,
    background = '#000000', groups_bg = '#111111', accent = '#222222', groups_radius = 8,
    transparent = '#00000000',
}
package.loaded.naughty = { notification_closed_reason = { expired = 1, dismissed_by_user = 2 } }
local dismiss_button
package.loaded['widget.notif-center.build-notifbox.notifbox-ui-elements'] = {
    notifbox_dismiss = function()
        dismiss_button = widget()
        return dismiss_button
    end,
    notifbox_icon = widget, notifbox_appname = widget,
    notifbox_title = widget, notifbox_message = widget, notifbox_actions = widget,
}

local popup = dofile(home .. '/.config/awesome/library/notification-popup-reflow.lua')
local build_card = dofile(home .. '/.config/awesome/widget/notif-center/build-notifbox/notifbox-builder.lua')

local function notification(fields)
    local value = fields or {}
    local signals = {}
    value.destroy_count = 0
    function value:connect_signal(name, handler) signals[name] = handler end
    function value:disconnect_signal(name, handler)
        if signals[name] == handler then signals[name] = nil end
    end
    function value:destroy(reason)
        self.destroy_count = self.destroy_count + 1
        self.destroy_reason = reason
        if signals.destroyed then signals.destroyed() end
    end
    return value
end

local removed = 0
local view = {
    remove_card = function(card, dismiss)
        removed = removed + 1
        if dismiss then card:emit_signal('widget::dismiss') end
        card:emit_signal('widget::removed')
    end,
}
local function card_for(n)
    return build_card(n, nil, 'Title', 'Message', 'Example Browser', nil, view)
end

-- The popup can expire while the notification remains available in Info Center.
local retained = notification()
local box = { visible = true, _private = { notification = { retained } } }
box._private.destroy_callback = function() box._private.notification = {} end
popup.release(box, retained)
assert(not box.visible and retained.destroy_count == 0, 'releasing popup destroyed its notification')

local card = card_for(retained)
card.clicks[1].callback()
assert(retained.destroy_count == 1 and retained.destroy_reason == 2,
    'clicking the retained card did not dismiss the notification')
assert(raised == 1 and toggles == 1 and removed == 1,
    'clicking the retained card did not raise the matching client and close Info Center')

local action_count = 0
local with_action = notification({ run = function() action_count = action_count + 1 end })
card_for(with_action).clicks[1].callback()
assert(action_count == 1 and with_action.destroy_count == 1 and raised == 1,
    'default action did not run before the client-name fallback')

local dbus = notification({ _private = { _unique_sender = ':1.2' } })
card_for(dbus).clicks[1].callback()
assert(dbus.destroy_count == 1 and dbus.destroy_reason == 2 and raised == 1,
    'D-Bus notification did not use its default action path')

local dismissed = notification()
card_for(dismissed)
dismiss_button.clicks[1].callback()
assert(dismissed.destroy_count == 1 and raised == 1,
    'dismiss button raised an application instead of dismissing its notification')

print('notification card action tests passed')

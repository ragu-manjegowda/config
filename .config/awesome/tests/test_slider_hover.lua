local config_dir = assert(os.getenv('HOME')) .. '/.config/awesome/'
local signals = {}
awesome = { connect_signal = function(name, callback)
    signals[name] = signals[name] or {}
    signals[name][#signals[name] + 1] = callback
end }
mouse = {}

local hover = dofile(config_dir .. 'widget/slider-hover.lua')
local function make_slider()
    local widget = { signals = {}, presses = 0 }
    function widget:connect_signal(name, callback)
        self.signals[name] = callback
    end
    function widget:press()
        self.presses = self.presses + 1
    end
    hover.attach(widget)
    return widget
end

local panel = { cursor = 'left_ptr' }
local slider = make_slider()
mouse.current_wibox = panel
slider.signals['mouse::enter']()
assert(panel.cursor == 'hand1', 'interactive slider did not show a hand on hover')
slider:press()
assert(slider.presses == 1, 'hover must not replace native slider button handling')
slider.signals['mouse::leave']()
assert(panel.cursor == 'left_ptr', 'slider did not restore the previous cursor')

slider.signals['mouse::enter']()
for _, callback in ipairs(signals['control_center::visibility']) do callback(false) end
assert(panel.cursor == 'left_ptr', 'closing Control Center left a hand cursor behind')

mouse.current_wibox = nil
slider.signals['mouse::enter']()
assert(panel.cursor == 'left_ptr', 'hover without a wibox changed a different panel')

print('slider hover tests passed')

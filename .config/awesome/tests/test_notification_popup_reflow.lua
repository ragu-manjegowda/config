local home = assert(os.getenv('HOME'))
local reflow = dofile(home .. '/.config/awesome/library/notification-popup-reflow.lua')

local screen_a = { valid = true }
local screen_b = { valid = true }
local callbacks = {}
local moved = {}
local notification = {}
local box = {
    screen = screen_a,
    visible = true,
    emit_signal = function(_, signal)
        assert(signal == 'property::geometry')
        moved[#moved + 1] = screen_a
    end,
}
local boxes = { [notification] = box }
local reposition = reflow.new(boxes, function(callback)
    callbacks[#callbacks + 1] = callback
end)

local detached = 0
box._private = {
    notification = { notification },
    destroy_callback = function()
        detached = detached + 1
        box._private.notification = {}
    end,
}

reposition(screen_a)
reposition(screen_a)
assert(#callbacks == 1, 'repeated workarea changes scheduled duplicate stack reflows')
assert(#moved == 0 and box.visible, 'reflow recreated or moved the popup before layout settled')
callbacks[1]()
assert(#moved == 1 and box.visible, 'visible popup was not repositioned in place')

reposition(screen_b)
callbacks[2]()
assert(#moved == 1, 'popup moved in response to another screen')

box.visible = false
reposition(screen_a)
callbacks[3]()
assert(#moved == 1, 'dismissed popup was repositioned')

box.visible = true
reposition(screen_a)
screen_a.valid = false
callbacks[4]()
assert(#moved == 1, 'popup moved after its screen was removed')

screen_a.valid = true
reposition(screen_a)
callbacks[5]()
assert(#moved == 2, 'removed screen prevented later popup reflows')

reflow.release(box, notification)
assert(not box.visible and detached == 1, 'hidden popup remains in Naughty placement stack')
reflow.release(box, notification)
assert(detached == 1, 'popup was detached twice')
assert(notification and not notification.destroyed, 'popup cleanup destroyed the retained notification')

print('notification popup reflow tests passed')

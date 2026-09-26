local home = assert(os.getenv('HOME'))
local backdrop = dofile(home .. '/.config/awesome/layout/center-backdrop.lua')

local screen = {
    geometry = { x = 1920, y = 100, width = 800, height = 600 },
    top_panel = { visible = true, height = 69 }
}
local overlay = { visible = false }

backdrop.show(overlay, screen)
assert(overlay.visible and overlay.x == 1920 and overlay.width == 800)
assert(overlay.y == 169 and overlay.height == 531,
    'visible top panel was covered by the click-capturing backdrop')

screen.top_panel.visible = false
backdrop.show(overlay, screen)
assert(overlay.y == 100 and overlay.height == 600,
    'fullscreen backdrop left a gap above the hidden top panel')

screen.top_panel = nil
screen.geometry = { x = 0, y = 0, width = 2880, height = 1800 }
backdrop.show(overlay, screen)
assert(overlay.x == 0 and overlay.y == 0 and overlay.width == 2880 and overlay.height == 1800,
    'recreated screen retained stale backdrop geometry')

print('center backdrop geometry tests passed')

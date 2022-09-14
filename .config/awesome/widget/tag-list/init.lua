--      ████████╗ █████╗  ██████╗     ██╗     ██╗███████╗████████╗
--      ╚══██╔══╝██╔══██╗██╔════╝     ██║     ██║██╔════╝╚══██╔══╝
--         ██║   ███████║██║  ███╗    ██║     ██║███████╗   ██║
--         ██║   ██╔══██║██║   ██║    ██║     ██║╚════██║   ██║
--         ██║   ██║  ██║╚██████╔╝    ███████╗██║███████║   ██║
--         ╚═╝   ╚═╝  ╚═╝ ╚═════╝     ╚══════╝╚═╝╚══════╝   ╚═╝

-- ===================================================================
-- Initialization
-- ===================================================================


local awful = require('awful')
local wibox = require('wibox')
local dpi = require('beautiful').xresources.apply_dpi
local clickable_container = require('widget.clickable-container')

-- define module table
local tag_list = {}


-- ===================================================================
-- Widget Creation Functions
-- ===================================================================

-- Update the taglist
local function list_update(w, buttons, label, data, objects)
     -- update the widgets, creating them if needed
   w:reset()
   for i, o in ipairs(objects) do
      local cache = data[o]
      local ib, tb, bgb, tbm, ibm, l, bg_clickable
      if cache then
         ib = cache.ib
         tb = cache.tb
         bgb = cache.bgb
         tbm = cache.tbm
         ibm = cache.ibm
      else
         local icondpi = 5
         ib = wibox.widget.imagebox()
         tb = wibox.widget.textbox()
         bgb = wibox.container.background()
         tbm = wibox.container.margin(tb, dpi(4), dpi(16))
         ibm = wibox.container.margin(ib, dpi(icondpi), dpi(icondpi), dpi(icondpi), dpi(icondpi))
         l = wibox.layout.fixed.horizontal()
         bg_clickable = clickable_container()

         -- All of this is added in a fixed widget
         l:fill_space(true)
         l:add(ibm)
         bg_clickable:set_widget(l)

         -- And all of this gets a background
         bgb:set_widget(bg_clickable)

         data[o] = {
            ib = ib,
            tb = tb,
            bgb = bgb,
            tbm = tbm,
            ibm = ibm
         }
      end

      local text, bg, bg_image, icon, args = label(o, tb)
      args = args or {}

      bgb:set_bg(bg)
      if type(bg_image) == 'function' then
         -- TODO: Why does this pass nil as an argument?
         bg_image = bg_image(tb, o, nil, objects, i)
      end

      bgb:set_bgimage(bg_image)
      if icon then
         ib.image = icon
      else
         ibm:set_margins(0)
      end

      bgb.shape = args.shape
      bgb.shape_border_width = args.shape_border_width
      bgb.shape_border_color = args.shape_border_color

      w:add(bgb)
   end
end

-- create the tag list widget
tag_list.create = function(s)
    return awful.widget.taglist{
        screen = s,
        filter = awful.widget.taglist.filter.noempty,
        update_function = list_update,
        layout = wibox.layout.fixed.horizontal(),
    }
end

return tag_list

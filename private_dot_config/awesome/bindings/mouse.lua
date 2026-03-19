local gears = require("gears")
local awful = require("awful")

local mouse_buttons = gears.table.join(
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
)

return mouse_buttons

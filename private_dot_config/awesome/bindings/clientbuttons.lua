local gears = require("gears")
local awful = require("awful")
local consts = require("consts")

local clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", {
			raise = true,
		})
	end),
	awful.button({ consts.modkey }, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", {
			raise = true,
		})
		awful.mouse.client.move(c)
	end),
	awful.button({ consts.modkey }, 2, function(c)
		c:emit_signal("request::activate", "mouse_click", {
			raise = true,
		})
		c.floating = true
		awful.mouse.client.resize(c)
	end),
	awful.button({ consts.modkey }, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", {
			raise = true,
		})
		awful.mouse.client.resize(c)
	end)
)

return clientbuttons

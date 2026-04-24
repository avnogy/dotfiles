local gears = require("gears")
local awful = require("awful")
local consts = require("consts")

local clientkeys = gears.table.join(
	awful.key({ consts.modkey }, "f", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, {
		description = "toggle fullscreen",
		group = "client",
	}),
	awful.key({ consts.modkey, "Shift" }, "c", function(c)
		c:kill()
	end, {
		description = "close",
		group = "client",
	}),
	awful.key({ consts.altkey }, "F4", function(c)
		c:kill()
	end, {
		description = "close",
		group = "client",
	}),
	awful.key({ consts.modkey, "Control" }, "space", awful.client.floating.toggle, {
		description = "toggle floating",
		group = "client",
	}),
	awful.key({ consts.modkey, "Control" }, "Return", function(c)
		c:swap(awful.client.getmaster())
	end, {
		description = "move to master",
		group = "client",
	}),
	awful.key({ consts.modkey }, "o", function(c)
		c:move_to_screen()
	end, {
		description = "move to screen",
		group = "client",
	}),
	awful.key({ consts.modkey }, "t", function(c)
		c.ontop = not c.ontop
	end, {
		description = "toggle keep on top",
		group = "client",
	}),
	awful.key({ consts.modkey }, "n", function(c)
		-- The client currently has the input focus, so it cannot be
		-- minimized, since minimized clients can't have the focus.
		c.minimized = true
	end, {
		description = "minimize",
		group = "client",
	}),
	awful.key({ consts.modkey, "Shift" }, "space", function(c)
		c.floating = false
		awful.layout.arrange(c.screen)
	end, {
		description = "force tiled",
		group = "client",
	}),
	awful.key({ consts.modkey }, "Home", function(c)
		c.opacity = c.opacity - 0.01
	end),
	awful.key({ consts.modkey }, "End", function(c)
		c.opacity = c.opacity + 0.01
	end)
)

return clientkeys

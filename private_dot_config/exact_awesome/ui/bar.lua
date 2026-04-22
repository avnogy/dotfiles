local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")

local consts = require("consts")

local mykeyboardlayout = awful.widget.keyboardlayout()
local battery_widget = require("widgets.battery")
local network_widget = require("widgets.network")
local volume = require("widgets.volume")
local volume_widget = volume.widget
local home_widget = require("widgets.home")
local ram_widget = require("widgets.ram")
local gpu_widget = require("widgets.gpu")
local cpu_widget = require("widgets.cpu")
local mytextclock = wibox.widget.textclock("%F %T ", 1)

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
	awful.button({}, 1, function(t)
		t:view_only()
	end),
	awful.button({ consts.modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({ consts.modkey }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({}, 4, function(t)
		awful.tag.viewnext(t.screen)
	end),
	awful.button({}, 5, function(t)
		awful.tag.viewprev(t.screen)
	end)
)

local wallpaper = require("ui.wallpaper")

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", wallpaper.apply_current)

awful.screen.connect_for_each_screen(function(s)
	wallpaper.apply_current(s)

	local tags = awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

	for _, tag in ipairs(tags) do
		tag:connect_signal("property::layout", function(t)
			t.gap = t.layout == awful.layout.suit.max.fullscreen and 0 or beautiful.useless_gap
		end)
	end

	s.mypromptbox = awful.widget.prompt()
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist({
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = taglist_buttons,
	})

	local tasklist_buttons = gears.table.join(
		awful.button({}, 1, function(c)
			if c == client.focus then
				c.minimized = true
			else
				c:emit_signal("request::activate", "tasklist", { raise = true })
			end
		end),
		awful.button({}, 3, function()
			awful.menu.client_list({ theme = { width = 250 } })
		end),
		awful.button({}, 4, function()
			awful.client.focus.byidx(1)
		end),
		awful.button({}, 5, function()
			awful.client.focus.byidx(-1)
		end)
	)

	s.mytasklist = awful.widget.tasklist({
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = tasklist_buttons,
	})

	-- Create the wibox
	s.mywibox = awful.wibar({ position = "top", screen = s, type = "dock" })

	-- Add widgets to the wibox
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			s.mytaglist,
			s.mypromptbox,
		},
		s.mytasklist, -- Middle widget
		{ -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			wibox.widget.systray(),
			mykeyboardlayout,
			network_widget,
			volume_widget,
			home_widget,
			ram_widget,
			gpu_widget,
			cpu_widget,
			battery_widget,
			mytextclock,
		},
	})
end)

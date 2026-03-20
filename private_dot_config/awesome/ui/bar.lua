local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")

local consts = require("consts")


local mykeyboardlayout = awful.widget.keyboardlayout()
local battery_widget = require("widgets.battery")
local ipv4_widget = require("widgets.ipv4")
local net_down_widget = require("widgets.net_down")
local net_up_widget = require("widgets.net_up")
local volume_widget = require("widgets.volume")
local home_used_widget = require("widgets.home_used")
local home_total_widget = require("widgets.home_total")
local ram_widget = require("widgets.ram")
local gpu_widget = require("widgets.gpu")
local cpu_widget = require("widgets.cpu")
local mytextclock = wibox.widget.textclock("%F %T ", 1)

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
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
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)


local set_wallpaper = require("ui.wallpaper")

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)


awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    s.mypromptbox = awful.widget.prompt()
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    local tasklist_buttons = gears.table.join(
        awful.button({}, 1, function(c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal(
                    "request::activate",
                    "tasklist",
                    { raise = true }
                )
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
        end))


    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }


    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        {             -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.systray(),
            mykeyboardlayout,
            ipv4_widget,
            net_down_widget,
            net_up_widget,
            volume_widget,
            home_used_widget,
            home_total_widget,
            ram_widget,
            gpu_widget,
            cpu_widget,
            battery_widget,
            mytextclock,
        },
    }
end)

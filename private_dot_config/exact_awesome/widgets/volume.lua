local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

local consts = require("consts")
local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()
local current_notification

local function notify(volume, muted)
	local msg = muted and "Muted" or volume .. "%"
	current_notification = naughty.notify({
		title = "Volume",
		text = msg,
		urgency = "low",
		timeout = 1,
		replaces_id = current_notification and current_notification.id or nil,
	})
end

local function change(step)
	awful.spawn.easy_async_with_shell(
		"pactl set-sink-volume @DEFAULT_SINK@ "
			.. step
			.. " > /dev/null && pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1 {print $5}'",
		function(stdout)
			local volume = stdout:match("(%d+)")
			if volume then
				notify(volume, false)
			end
		end
	)
end

local function toggle_mute()
	awful.spawn.easy_async_with_shell(
		"pactl set-sink-mute @DEFAULT_SINK@ toggle > /dev/null && pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'",
		function(stdout)
			local muted = stdout:match("%S+")
			if muted == "yes" then
				notify(0, true)
			else
				awful.spawn.easy_async_with_shell(
					"pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1 {print $5}'",
					function(vol)
						local volume = vol:match("%d+")
						if volume then
							notify(volume, false)
						end
					end
				)
			end
		end
	)
end

local function update()
	local muted = helpers.read_command("pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'")
	local volume = "n/a"

	if muted == "yes" then
		volume = "0%"
	elseif muted == "no" then
		volume = helpers.read_command("pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1 {print $5}'") or "n/a"
	end

	widget:set_text(string.format("♪%s | ", volume))
end

widget:buttons(gears.table.join(awful.button({}, 1, function()
	awful.spawn({ consts.terminal, "-e", "pulsemixer" })
end)))

gears.timer({
	timeout = 1,
	autostart = true,
	call_now = true,
	callback = update,
})

return {
	widget = widget,
	change = change,
	toggle_mute = toggle_mute,
}

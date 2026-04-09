local gears = require("gears")
local awful = require("awful")

local consts = require("consts")
local helpers = require("widgets.helpers")

local STACK_TAG = "myvolumetag"

local widget = helpers.new_text_widget()

local function notify(volume, muted)
	local msg = muted and "Muted" or "Volume: " .. volume .. "%"
	awful.spawn({
		"dunstify",
		"-t 1000",
		"-a changevolume",
		"-u low",
		"-h string:x-dunst-stack-tag:" .. STACK_TAG,
		"-h int:value:" .. volume,
		msg,
	}, false)
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

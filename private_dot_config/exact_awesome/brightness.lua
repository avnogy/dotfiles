local awful = require("awful")
local naughty = require("naughty")

local current_notification

local function notify(brightness)
	current_notification = naughty.notify({
		title = "Brightness",
		text = brightness .. "%",
		urgency = "low",
		timeout = 1,
		replaces_id = current_notification and current_notification.id or nil,
	})
end

local function change(step)
	awful.spawn.easy_async_with_shell(
		"brightnessctl set " .. step .. " > /dev/null && brightnessctl | grep -oP '(?<=\\().*?(?=%)'",
		function(stdout)
			local brightness = stdout:match("(%d+)")
			if brightness then
				notify(brightness)
			end
		end
	)
end

return {
	change = change,
}

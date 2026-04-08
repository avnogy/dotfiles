local gears = require("gears")

local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()

local function update()
	local f = io.popen("df -B1 /home 2>/dev/null")
	if not f then
		widget:set_text("HOME n/a | ")
		return
	end
	local _ = f:read("*l")
	local line = f:read("*l")

	f:close()
	if not line then
		widget:set_text("HOME n/a | ")
		return
	end
	local used = nil
	local total = nil
	for field in line:gmatch("%S+") do
		local n = tonumber(field)
		if n then
			if not total then
				total = n
			elseif not used then
				used = n
				break
			end
		end
	end
	local used_text = used and helpers.fmt_human(used, 1000) or "n/a"
	local total_text = total and helpers.fmt_human(total, 1000) or "n/a"
	widget:set_text(string.format("HOME %s / %s | ", used_text, total_text))
end

gears.timer({
	timeout = 5,
	autostart = true,
	call_now = true,
	callback = update,
})

return widget

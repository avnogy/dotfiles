local gears = require("gears")
local awful = require("awful")

local consts = require("consts")
local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()
local previous

local function update()
	local current = helpers.read_cpu_stats()
	if not current then
		widget:set_text("CPU n/a% | ")
		return
	end

	if not previous or previous[1] == 0 then
		previous = current
		widget:set_text("CPU n/a% | ")
		return
	end

	local current_total = 0
	local previous_total = 0
	for i = 1, 7 do
		current_total = current_total + current[i]
		previous_total = previous_total + previous[i]
	end

	local total_delta = current_total - previous_total
	if total_delta == 0 then
		previous = current
		widget:set_text("CPU n/a% | ")
		return
	end

	local current_active = current[1] + current[2] + current[3] + current[6] + current[7]
	local previous_active = previous[1] + previous[2] + previous[3] + previous[6] + previous[7]
	previous = current

	local percent = math.floor(100 * (current_active - previous_active) / total_delta)
	widget:set_text(string.format("CPU %s%% | ", tostring(percent)))
end

widget:buttons(gears.table.join(awful.button({}, 1, function()
	awful.spawn({ consts.terminal, "-e", "htop" })
end)))

gears.timer({
	timeout = 1,
	autostart = true,
	call_now = true,
	callback = update,
})

return widget

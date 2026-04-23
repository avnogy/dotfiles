local gears = require("gears")
local naughty = require("naughty")
local beautiful = require("beautiful")

local CRITICAL_BATTERY_LEVEL = 15
local WARNING_THRESHOLD_SECONDS = 300
local NOTIFICATION_TIMEOUT = 25
local TIMEOUT = 10

local global_last_warning
local helpers = require("widgets.helpers")
local battery_text = helpers.new_text_widget()
local battery_path = helpers.find_battery()

local function extract_time(status)
	if status ~= "Discharging" then
		return ""
	end
	local energy = helpers.read_number(battery_path .. "/energy_now")
	local power = helpers.read_number(battery_path .. "/power_now")
	if not energy or not power or power <= 0 then
		return ""
	end
	local hours = energy / power
	local h = math.floor(hours)
	local m = math.floor((hours - h) * 60)
	return string.format("(%d:%02d)", h, m)
end

local function state_symbol(status)
	if status == "Charging" then
		return "↑"
	elseif status == "Discharging" then
		return "↓"
	elseif status == "Full" or status == "Not charging" then
		return "o"
	else
		return "?"
	end
end

local function maybe_warn_battery_low(charge, status)
	if not charge or charge >= CRITICAL_BATTERY_LEVEL or status == "Charging" then
		return
	end

	if global_last_warning and os.difftime(os.time(), global_last_warning) <= WARNING_THRESHOLD_SECONDS then
		return
	end

	global_last_warning = os.time()
	local theme = beautiful.get()
	naughty.notify({
		title = "Battery low",
		text = "Battery is dying (" .. charge .. "%)",
		timeout = NOTIFICATION_TIMEOUT,
		bg = theme and theme.bg_urgent or "#F06060",
		fg = theme and theme.fg_urgent or "#EEE9EF",
	})
end

if not battery_path then
	battery_text:set_text("")
	return battery_text
end

local function update_widget()
	local charge = helpers.read_number(battery_path .. "/capacity")
	local status = helpers.read_all(battery_path .. "/status")

	if status then
		status = status:match("^%s*(.-)%s*$")
	end

	if not charge or not status or status == "" then
		battery_text:set_text("")
		return
	end

	battery_text:set_text(string.format("BAT %s %d%% %s | ", state_symbol(status), charge, extract_time(status)))
	maybe_warn_battery_low(charge, status)
end

gears.timer({
	timeout = TIMEOUT,
	autostart = true,
	call_now = true,
	callback = update_widget,
})

return battery_text

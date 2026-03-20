local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")

local CRITICAL_BATTERY_LEVEL = 15
local WARNING_THRESHOLD_SECONDS = 300
local NOTIFICATION_TIMEOUT = 25
local TIMEOUT = 10

local global_last_warning

local function has_battery()
    local handle = io.popen("test -d /sys/class/power_supply/BAT0 && echo yes")
    if not handle then
        return false
    end

    local result = handle:read("*l")
    handle:close()
    return result == "yes"
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

local function extract_time(stdout, status)
    if status ~= "Discharging" then
        return ""
    end

    local h, m = stdout:match("(%d+):(%d+):%d+ remaining")
    if h and m then
        return string.format("(%d:%02d)", tonumber(h), tonumber(m))
    end

    return ""
end

local function parse_battery(stdout)
    local status, charge = stdout:match(":%s*([%a%s]+),%s*(%d+)%%")
    if status then
        status = status:match("^%s*(.-)%s*$")
    end
    return tonumber(charge), status
end

local function maybe_warn_battery_low(charge, status)
    if not charge or charge >= CRITICAL_BATTERY_LEVEL or status == "Charging" then
        return
    end

    if global_last_warning and os.difftime(os.time(), global_last_warning) <= WARNING_THRESHOLD_SECONDS then
        return
    end

    global_last_warning = os.time()
    naughty.notify {
        title = "Battery low",
        text = "Battery is dying (" .. charge .. "%)",
        timeout = NOTIFICATION_TIMEOUT,
        bg = "#F06060",
        fg = "#EEE9EF",
    }
end

local battery_text = wibox.widget.textbox()

if not has_battery() then
    return battery_text
end

local function update_widget()
    awful.spawn.easy_async("acpi", function(stdout)
        local charge, status = parse_battery(stdout)
        if not charge or not status then
            battery_text.text = ""
            return
        end

        battery_text.text = string.format(
            "BAT %s %d%% %s",
            state_symbol(status),
            charge,
            extract_time(stdout, status)
        )

        maybe_warn_battery_low(charge, status)
    end)
end

gears.timer {
    timeout = TIMEOUT,
    autostart = true,
    call_now = true,
    callback = update_widget
}

return battery_text

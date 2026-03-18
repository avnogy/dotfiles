-------------------------------------------------
-- Battery Widget (slstatus-style)
-- Shows: BAT ↓ 75% (1:51)
-------------------------------------------------

local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")
local gfs = require("gears.filesystem")
local dpi = require('beautiful').xresources.apply_dpi

-- Constants
local CRITICAL_BATTERY_LEVEL = 15
local WARNING_THRESHOLD_SECONDS = 300
local NOTIFICATION_TIMEOUT = 25

local DEFAULT_CONFIG = {
    font = 'Play 8',
    path_to_icons = "/usr/share/icons/Arc/status/symbolic/",
    timeout = 10,
    enable_battery_warning = true,
}

-- Global state
local widgets = {}
local global_timer
local global_last_warning
local battery_config = nil
local icon_cache = {}

-------------------------------------------------
-- Helpers (slstatus-style)
-------------------------------------------------

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

-------------------------------------------------
-- Icon logic (unchanged)
-------------------------------------------------

local function get_battery_type(charge, status)
    if charge >= 80 then
        return (status == "Charging") and "battery-full-charging-symbolic" or "battery-full-symbolic"
    elseif charge >= 60 then
        return (status == "Charging") and "battery-good-charging-symbolic" or "battery-good-symbolic"
    elseif charge >= 40 then
        return (status == "Charging") and "battery-low-charging-symbolic" or "battery-low-symbolic"
    elseif charge >= 15 then
        return (status == "Charging") and "battery-caution-charging-symbolic" or "battery-caution-symbolic"
    else
        return (status == "Charging") and "battery-empty-charging-symbolic" or "battery-empty-symbolic"
    end
end

local function get_icon_path(battery_type)
    if not icon_cache[battery_type] then
        icon_cache[battery_type] = battery_config.path_to_icons .. battery_type .. ".svg"
    end
    return icon_cache[battery_type]
end

-------------------------------------------------
-- Parsing
-------------------------------------------------

local function parse_battery(stdout)
    local status, charge = stdout:match(":%s*([%a%s]+),%s*(%d+)%%")
    if status then
        status = status:match("^%s*(.-)%s*$")
    end
    return tonumber(charge), status
end

-------------------------------------------------
-- Warning
-------------------------------------------------

local function check_battery_warning(charge, status)
    if not battery_config.enable_battery_warning then return end

    if charge and charge < CRITICAL_BATTERY_LEVEL and status ~= "Charging" then
        if not global_last_warning or os.difftime(os.time(), global_last_warning) > WARNING_THRESHOLD_SECONDS then
            global_last_warning = os.time()
            naughty.notify {
                title = "Battery low",
                text = "Battery is dying (" .. charge .. "%)",
                timeout = NOTIFICATION_TIMEOUT,
                bg = "#F06060",
                fg = "#EEE9EF",
            }
        end
    end
end

-------------------------------------------------
-- Main update
-------------------------------------------------

local function update_all_widgets()
    awful.spawn.easy_async("acpi", function(stdout)
        local charge, status = parse_battery(stdout)
        if not charge or not status then return end

        local symbol = state_symbol(status)
        local time = extract_time(stdout, status)
        local battery_type = get_battery_type(charge, status)

        local text = string.format("BAT %s %d%% %s", symbol, charge, time)

        for _, w in ipairs(widgets) do
            w.icon:set_image(get_icon_path(battery_type))
            w.level.text = text
        end

        check_battery_warning(charge, status)
    end)
end

-------------------------------------------------
-- Widget factory
-------------------------------------------------

local function worker(user_args)
    local args = user_args or {}

    if not battery_config then
        battery_config = {}
        for k, v in pairs(DEFAULT_CONFIG) do
            battery_config[k] = args[k] ~= nil and args[k] or v
        end
    end

    if not global_timer then
        global_timer = gears.timer {
            timeout = battery_config.timeout,
            autostart = true,
            call_now = true,
            callback = update_all_widgets
        }
    end

    local imagebox = wibox.widget.imagebox()
    local level_widget = wibox.widget {
        font = battery_config.font,
        widget = wibox.widget.textbox
    }

    local widget = wibox.widget {
        imagebox,
        level_widget,
        layout = wibox.layout.fixed.horizontal,
    }

    table.insert(widgets, { icon = imagebox, level = level_widget })

    return widget
end

-------------------------------------------------

return setmetatable({}, {
    __call = function(_, ...)
        return worker(...)
    end
})

local gears = require("gears")
local awful = require("awful")

local consts = require("consts")
local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()

local function update()
    local muted = helpers.read_command("pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'")
    local volume = "n/a"

    if muted == "yes" then
        volume = "0%"
    elseif muted == "no" then
        volume = helpers.read_command("pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1 {print $5}'") or "n/a"
    end

    widget:set_text(string.format("%s | ", volume))
end

widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awful.spawn({ consts.terminal, "-e", "pulsemixer" })
    end)
))

gears.timer {
    timeout = 1,
    autostart = true,
    call_now = true,
    callback = update,
}

return widget

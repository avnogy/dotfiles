local gears = require("gears")

local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()
local previous
local previous_iface

local function update()
    local iface = helpers.get_active_iface()
    local current = iface and helpers.read_number("/sys/class/net/" .. iface .. "/statistics/tx_bytes") or nil
    local text = "n/a"

    if iface ~= previous_iface then
        previous = nil
        previous_iface = iface
    end

    if current and previous then
        text = helpers.fmt_human(current - previous, 1024)
    end

    previous = current
    widget:set_text(string.format("out: %s | ", text))
end

gears.timer {
    timeout = 1,
    autostart = true,
    call_now = true,
    callback = update,
}

return widget

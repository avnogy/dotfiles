local gears = require("gears")
local awful = require("awful")

local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()

local function update()
    local iface = helpers.get_active_iface()
    local ip = helpers.get_active_ipv4() or "n/a"
    local label = helpers.get_wifi_name(iface) or iface or "n/a"

    widget:set_text(string.format("| %s: %s | ", label, ip))
end

widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awful.spawn({ "nm-connection-editor" })
    end)
))

gears.timer {
    timeout = 1,
    autostart = true,
    call_now = true,
    callback = update,
}

return widget

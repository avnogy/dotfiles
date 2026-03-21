local gears = require("gears")
local awful = require("awful")

local helpers = require("widgets.helpers")
local poller = require("widgets.network_shared")

local widget = helpers.new_text_widget()
local prev_rx
local prev_tx

local function update()
    local iface = poller.last_iface
    local label = poller.last_wifi or iface or "n/a"
    local ip = poller.last_ip or "n/a"

    local rx = poller.last_rx
    local tx = poller.last_tx
    local rx_text = "n/a"
    local tx_text = "n/a"

    if rx and prev_rx then
        rx_text = "↓ " .. helpers.fmt_human(rx - prev_rx, 1024)
    end
    if tx and prev_tx then
        tx_text = "↑ " .. helpers.fmt_human(tx - prev_tx, 1024)
    end

    prev_rx = rx
    prev_tx = tx

    widget:set_text(string.format("| %s: %s | %s %s | ", label, ip, rx_text, tx_text))
end

widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awful.spawn({ "nm-connection-editor" })
    end)
))

poller:connect_signal("update", update)
update()

return widget

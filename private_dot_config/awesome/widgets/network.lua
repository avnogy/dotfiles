local gears = require("gears")
local awful = require("awful")

local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()
local prev_rx, prev_tx

local function update()
	local iface, ip, wifi = nil, "n/a", nil

	local p = io.popen("ip route show default 2>/dev/null | head -1")
	if p then
		local line = p:read("*l")
		p:close()
		iface = line and line:match("dev%s+(%S+)")
	end

	if iface then
		p = io.popen("ip -4 addr show dev " .. iface .. " 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1")
		if p then
			ip = p:read("*l") or "n/a"
			p:close()
		end

		p = io.popen("nmcli -t -f GENERAL.CONNECTION device show " .. iface .. " 2>/dev/null")
		if p then
			for line in p:lines() do
				local essid = line:match("GENERAL.CONNECTION:%s*(.+)")
				if essid and essid ~= "" and essid ~= "--" then
					wifi = essid
					break
				end
			end
			p:close()
		end
	end

	local label = wifi or iface or "n/a"
	local rx, tx = nil, nil

	if iface then
		local f = io.open("/sys/class/net/" .. iface .. "/statistics/rx_bytes")
		if f then
			rx = tonumber(f:read("*a"))
			f:close()
		end
		f = io.open("/sys/class/net/" .. iface .. "/statistics/tx_bytes")
		if f then
			tx = tonumber(f:read("*a"))
			f:close()
		end
	end

	local rx_text, tx_text = "n/a", "n/a"
	if rx and prev_rx then
		rx_text = "↓ " .. helpers.fmt_human(rx - prev_rx, 1024)
	end
	if tx and prev_tx then
		tx_text = "↑ " .. helpers.fmt_human(tx - prev_tx, 1024)
	end

	widget:set_text(string.format("| %s: %s | %s %s | ", label, ip, rx_text, tx_text))
	prev_rx, prev_tx = rx, tx
end

widget:buttons(gears.table.join(awful.button({}, 1, function()
	awful.spawn({ "nm-connection-editor" })
end)))

gears.timer({ timeout = 1, autostart = true, callback = update })

update()

return widget

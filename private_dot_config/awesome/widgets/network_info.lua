-- network_widget.lua
local wibox   = require("wibox")
local awful   = require("awful")
local gears   = require("gears")
local beautiful = require("beautiful")

-- helper to get the first active interface (eth0 or wlan0)
local function get_active_iface()
    local handle = io.popen("ip -o -4 addr show up | awk '{print $2}'")
    if not handle then return nil end
    local result = handle:read("*a")
    handle:close()
    for iface in result:gmatch("[^\n]+") do
        if iface == "eth0" or iface == "enp4s0" or iface == "wlan0" then
            return iface
        end
    end
    return nil
end

-- helper to get the IP address of a given interface
local function get_ip(iface)
    if not iface then return "—" end
    local cmd = string.format("ip -4 addr show %s | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}'", iface)
    local handle = io.popen(cmd)
    if not handle then return "—" end
    local ip = handle:read("*l") or "—"
    handle:close()
    return ip
end

-- widget definition
local net_widget = wibox.widget {
    {
        id     = "text",
        widget = wibox.widget.textbox,
        align  = "center",
        valign = "center",
    },
    layout = wibox.container.place,
    -- forced_width = 120,
    forced_height = 20,
}

-- update function
local function update()
    local iface = get_active_iface()
    local ip    = get_ip(iface)
    local txt   = iface and string.format("%s: %s", iface, ip) or "No link"
    net_widget.text:set_text(txt)
end

-- timer: refresh every 10 seconds
gears.timer {
    timeout   = 10,
    autostart = true,
    call_now  = true,
    callback  = update,
}

return net_widget

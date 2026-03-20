local wibox = require("wibox")
local gears = require("gears")

-- Follow the default route first, then fall back to the first non-loopback link.
local function get_active_iface()
    local handle = io.popen("ip -o route show to default | awk 'NR==1 {print $5}'")
    if not handle then return nil end
    local iface = handle:read("*l")
    handle:close()

    if iface and iface ~= "" then
        return iface
    end

    handle = io.popen("ip -o link show up | awk -F': ' '$2 != \"lo\" {print $2; exit}'")
    if not handle then return nil end
    iface = handle:read("*l")
    handle:close()

    return iface ~= "" and iface or nil
end

-- Read the first global IPv4 address for the interface.
local function get_ip(iface)
    if not iface then return "—" end
    local cmd = string.format(
        "ip -o -4 addr show dev %q scope global | awk 'NR==1 {split($4, a, \"/\"); print a[1]}'",
        iface
    )
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

gears.timer {
    timeout   = 2,
    autostart = true,
    call_now  = true,
    callback  = update,
}

return net_widget

local gears = require("gears")

local M = require("gears.object"){}

local iface = nil
local wifi_name = nil
local prev_rx = nil
local prev_tx = nil

local function get_active_iface()
    local h = io.popen("ip route show default 2>/dev/null")
    if h then
        local line = h:read("*l")
        h:close()
        if line then
            local dev = line:match("dev%s+(%S+)")
            if dev then
                return dev
            end
        end
    end
    local d = io.popen("ls /sys/class/net/ 2>/dev/null")
    if not d then
        return nil
    end
    for iface_name in d:lines() do
        if iface_name ~= "lo" then
            local f2 = io.open("/sys/class/net/" .. iface_name .. "/carrier", "r")
            if f2 then
                f2:close()
                d:close()
                return iface_name
            end
        end
    end
    d:close()
    return nil
end

local function get_wifi_name(iface_name)
    if not iface_name then
        return nil
    end

    local f = io.open("/proc/net/wireless", "r")
    if f then
        local found = false
        for line in f:lines() do
            if found then
                local fields = {}
                for field in line:gmatch("%S+") do
                    fields[#fields + 1] = field
                end
                if fields[1] and fields[1] == iface_name .. ":" then
                    f:close()
                    return iface_name
                end
                found = false
            end
            if line:match("^%s*" .. iface_name) then
                found = true
            end
        end
        f:close()
    end

    local h = io.popen("nmcli -t -f GENERAL.CONNECTION device show " .. iface_name .. " 2>/dev/null")
    if h then
        for line in h:lines() do
            local essid = line:match("GENERAL.CONNECTION:%s*(.+)")
            if essid and essid ~= "" and essid ~= "--" then
                h:close()
                return essid
            end
        end
        h:close()
    end

    return nil
end

local function get_ipv4(iface_name)
    if not iface_name then
        return nil
    end
    local h = io.popen("ip -4 addr show dev " .. iface_name .. " 2>/dev/null")
    if not h then
        return nil
    end
    for line in h:lines() do
        local ip = line:match("inet (%d+%.%d+%.%d+%.%d+)")
        if ip then
            h:close()
            return ip
        end
    end
    h:close()
    return nil
end

local function read_bytes(iface_name, kind)
    if not iface_name then
        return nil
    end
    local f = io.open("/sys/class/net/" .. iface_name .. "/statistics/" .. kind .. "_bytes", "r")
    if not f then
        return nil
    end
    local val = tonumber(f:read("*a"))
    f:close()
    return val
end

local function update()
    local new_iface = get_active_iface()
    local new_wifi = get_wifi_name(new_iface)
    local new_rx = read_bytes(new_iface, "rx")
    local new_tx = read_bytes(new_iface, "tx")
    local new_ip = get_ipv4(new_iface)

    if new_iface ~= iface or new_wifi ~= wifi_name or new_ip ~= M.last_ip or new_rx ~= prev_rx or new_tx ~= prev_tx then
        iface = new_iface
        wifi_name = new_wifi
        prev_rx = new_rx
        prev_tx = new_tx
        M.last_ip = new_ip
        M.last_iface = iface
        M.last_wifi = wifi_name
        M.last_rx = prev_rx
        M.last_tx = prev_tx
        M:emit_signal("update")
    end
end

gears.timer {
    timeout = 1,
    autostart = true,
    call_now = true,
    callback = update,
}

return M

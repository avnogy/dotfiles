local wibox = require("wibox")

local M = {}

function M.new_text_widget()
    return wibox.widget.textbox()
end

function M.fmt_human(num, base)
    local prefixes = base == 1000
        and { "", "k", "M", "G", "T", "P", "E", "Z", "Y" }
        or { "", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi" }
    local scaled = num
    local index = 1

    while index < #prefixes and scaled >= base do
        scaled = scaled / base
        index = index + 1
    end

    return string.format("%.1f %s", scaled, prefixes[index])
end

function M.read_number(path)
    local handle = io.open(path, "r")
    if not handle then
        return nil
    end

    local value = tonumber(handle:read("*l"))
    handle:close()
    return value
end

function M.read_all(path)
    local handle = io.open(path, "r")
    if not handle then
        return nil
    end

    local value = handle:read("*a")
    handle:close()
    return value
end

function M.read_command(command)
    local handle = io.popen(command)
    if not handle then
        return nil
    end

    local output = handle:read("*l")
    handle:close()
    return output
end

function M.get_active_iface()
    local iface = M.read_command("ip -o route show to default | awk 'NR==1 {print $5}'")
    if iface and iface ~= "" then
        return iface
    end

    iface = M.read_command("ip -o link show up | awk -F': ' '$2 != \"lo\" {print $2; exit}'")
    if iface and iface ~= "" then
        return iface
    end

    return nil
end

function M.get_active_ipv4()
    local iface = M.get_active_iface()
    if not iface then
        return nil
    end

    local ip = M.read_command(
        string.format(
            "ip -o -4 addr show dev %q scope global | awk 'NR==1 {split($4, a, \"/\"); print a[1]}'",
            iface
        )
    )

    if ip and ip ~= "" then
        return ip
    end

    return nil
end

function M.get_wifi_name(iface)
    if not iface then
        return nil
    end

    local essid = M.read_command("nmcli -t -f GENERAL.CONNECTION device show " .. iface .. " | awk -F: 'NR==1 {print $2}'")
    if essid and essid ~= "" and essid ~= "--" then
        return essid
    end

    essid = M.read_command("iw dev " .. iface .. " link | awk -F': ' '/SSID/ {print $2; exit}'")
    if essid and essid ~= "" then
        return essid
    end

    return nil
end

function M.read_df_bytes(path, field)
    local value = M.read_command("df -B1 " .. path .. " | awk 'NR==2 {print $" .. field .. "}'")
    return value and tonumber(value) or nil
end

function M.read_meminfo()
    local content = M.read_all("/proc/meminfo")
    if not content then
        return nil
    end

    local values = {}
    for key, value in content:gmatch("(%w+):%s+(%d+)") do
        values[key] = tonumber(value)
    end

    return values
end

function M.read_cpu_stats()
    local line = M.read_command("awk 'NR==1 {print $2, $3, $4, $5, $6, $7, $8}' /proc/stat")
    if not line then
        return nil
    end

    local stats = {}
    for value in line:gmatch("(%d+)") do
        stats[#stats + 1] = tonumber(value)
    end

    return #stats == 7 and stats or nil
end

function M.find_battery()
    local battery = M.read_command("find /sys/class/power_supply -maxdepth 1 -type d -name 'BAT*' | head -n1")
    if battery and battery ~= "" then
        return battery
    end

    return nil
end

return M

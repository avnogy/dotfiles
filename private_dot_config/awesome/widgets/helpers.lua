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

    local fmt = (scaled == math.floor(scaled)) and "%.0f %s" or "%.1f %s"
    return string.format(fmt, scaled, prefixes[index]) .. "B"
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

function M.read_df_bytes(path)
    local f = io.popen("df -B1 " .. path .. " 2>/dev/null")
    if not f then
        return nil
    end
    local _ = f:read("*l")
    local line = f:read("*l")
    f:close()
    if not line then
        return nil
    end
    local total = line:match("^%S+%s+%S+%s+(%d+)")
    return total and tonumber(total) or nil
end

function M.read_df_used(path)
    local f = io.popen("df -B1 " .. path .. " 2>/dev/null")
    if not f then
        return nil
    end
    local _ = f:read("*l")
    local line = f:read("*l")
    f:close()
    if not line then
        return nil
    end
    local used = line:match("^%S+%s+(%d+)")
    return used and tonumber(used) or nil
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
    local f = io.open("/proc/stat", "r")
    if not f then
        return nil
    end
    local line = f:read("*l")
    f:close()
    if not line then
        return nil
    end
    local stats = {}
    for value in line:gmatch("(%d+)") do
        stats[#stats + 1] = tonumber(value)
    end
    return #stats >= 7 and { stats[1], stats[2], stats[3], stats[4], stats[5], stats[6], stats[7] } or nil
end

function M.find_battery()
    local candidates = {
        "/sys/class/power_supply/BAT0",
        "/sys/class/power_supply/BAT1",
    }

    for _, battery in ipairs(candidates) do
        if M.read_number(battery .. "/capacity") then
            return battery
        end
    end

    return nil
end

return M

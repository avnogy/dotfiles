local gears = require("gears")
local awful = require("awful")

local consts = require("consts")
local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()

local function detect_nvidia_gpu()
    local index = helpers.read_command(
        "nvidia-smi --query-gpu=index --format=csv,noheader,nounits 2>/dev/null | head -n1"
    )

    if index and index ~= "" then
        return {
            backend = "nvidia",
            index = index,
        }
    end
end

local function score_drm_gpu(card)
    local score = 0
    local vendor = helpers.read_all(card .. "/device/vendor")
    local boot_vga = helpers.read_number(card .. "/device/boot_vga")

    if boot_vga == 0 then
        score = score + 10
    end

    if vendor == "0x10de\n" or vendor == "0x1002\n" then
        score = score + 5
    end

    return score
end

local function detect_drm_gpu()
    local handle = io.popen("find /sys/class/drm -maxdepth 1 -type l -name 'card[0-9]*' | sort")
    if not handle then
        return nil
    end

    local best_gpu
    local best_score

    for card in handle:lines() do
        local class = helpers.read_all(card .. "/device/class")
        local usage_path = card .. "/device/gpu_busy_percent"
        local usage = helpers.read_number(usage_path)

        if class and class:match("^0x03") and usage then
            local score = score_drm_gpu(card)
            if not best_score or score > best_score then
                best_gpu = {
                    backend = "drm",
                    usage_path = usage_path,
                }
                best_score = score
            end
        end
    end

    handle:close()
    return best_gpu
end

local gpu = detect_nvidia_gpu() or detect_drm_gpu()

local function read_usage()
    if not gpu then
        return nil
    end

    if gpu.backend == "nvidia" then
        local usage = helpers.read_command(
            "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits -i "
                .. gpu.index .. " 2>/dev/null | head -n1"
        )
        return usage and tonumber(usage) or nil
    end

    return helpers.read_number(gpu.usage_path)
end

local function update()
    local usage = read_usage()
    if not usage then
        widget:set_text("")
        return
    end

    widget:set_text(string.format("GPU %d%% | ", usage))
end

widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awful.spawn({ consts.terminal, "-e", "nvtop" })
    end)
))

gears.timer {
    timeout = 2,
    autostart = true,
    call_now = true,
    callback = update,
}

return widget

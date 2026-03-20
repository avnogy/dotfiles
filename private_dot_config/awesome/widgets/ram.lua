local gears = require("gears")

local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()

local function update()
    local values = helpers.read_meminfo()
    if not values then
        widget:set_text("RAM n/a | ")
        return
    end

    local total = values.MemTotal
    local free = values.MemFree
    local buffers = values.Buffers
    local cached = values.Cached
    local shmem = values.Shmem
    local sreclaimable = values.SReclaimable

    if not total or not free or not buffers or not cached or not shmem or not sreclaimable then
        widget:set_text("RAM n/a | ")
        return
    end

    local used = total - free - buffers - cached - sreclaimable + shmem
    widget:set_text(string.format("RAM %s | ", helpers.fmt_human(used * 1024, 1024)))
end

gears.timer {
    timeout = 2,
    autostart = true,
    call_now = true,
    callback = update,
}

return widget

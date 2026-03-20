local gears = require("gears")

local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()

local function update()
    local bytes = helpers.read_df_bytes("/home", 3)
    local value = bytes and helpers.fmt_human(bytes, 1024) or "n/a"
    widget:set_text(string.format("HOME %s / ", value))
end

gears.timer {
    timeout = 5,
    autostart = true,
    call_now = true,
    callback = update,
}

return widget

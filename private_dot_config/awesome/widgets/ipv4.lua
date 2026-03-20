local gears = require("gears")

local helpers = require("widgets.helpers")

local widget = helpers.new_text_widget()

local function update()
    widget:set_text(string.format("| %s | ", helpers.get_active_ipv4() or "n/a"))
end

gears.timer {
    timeout = 1,
    autostart = true,
    call_now = true,
    callback = update,
}

return widget

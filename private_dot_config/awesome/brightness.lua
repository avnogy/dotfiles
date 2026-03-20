local awful = require("awful")

local STACK_TAG = "mybrightnesstag"

local function notify(brightness)
    awful.spawn({
        "dunstify",
        "-t", "1000",
        "-a", "changebrightness",
        "-u", "low",
        "-h", "string:x-dunst-stack-tag:" .. STACK_TAG,
        "-h", "int:value:" .. brightness,
        "Brightness: " .. brightness .. "%"
    }, false)
end

local function change(step)
    awful.spawn.easy_async_with_shell(
        "brightnessctl set " .. step .. " > /dev/null && brightnessctl | grep -oP '(?<=\\().*?(?=%)'",
        function(stdout)
            local brightness = stdout:match("(%d+)")
            if brightness then
                notify(brightness)
            end
        end
    )
end

return {
    change = change,
}

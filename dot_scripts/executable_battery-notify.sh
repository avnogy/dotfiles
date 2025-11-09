#!/bin/bash

battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')

battery_status=$(acpi -b | grep -o "Charging\|Discharging")

if [ "$battery_status" = "Discharging" ] && [ "$battery_level" -le 20 ]; then
    dunstify -u critical "Battery Low" "Battery is at ${battery_level}%"
fi

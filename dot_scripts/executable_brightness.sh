#!/bin/bash

msgTag="mybrightnesstag"

# Change brightness silently
brightnessctl set "$@" > /dev/null

# Get brightness number from the second line
brightness=$(brightnessctl | grep -oP '(?<=\().*?(?=%)')


# Send notification
dunstify -t 1000 -a "changebrightness" -u low \
    -h string:x-dunst-stack-tag:$msgTag \
    -h int:value:"$brightness" \
    "Brightness: ${brightness}%"

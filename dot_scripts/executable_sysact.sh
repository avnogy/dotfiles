#!/bin/sh

# A dmenu wrapper script for system functions.
export WM="dwm"
ctl="systemctl"

lock(){
    kill -44 $(pidof slstatus)
    xset dpms force off
    slock
    kill -44 $(pidof slstatus)
}

case "$(printf "lock\ndisplay off\nshutdown\nreboot\nleave $WM\nhibernate\nsleep" | dmenu -i -p 'Action: ')" in
	'lock') (slock > /dev/null 2>&1 & xset dpms force off > /dev/null 2>&1) ;;
	'display off') xset dpms force off ;;
	'shutdown') $ctl poweroff -i ;;
	'reboot') $ctl reboot -i ;;
	"leave $WM") kill -TERM "$(pidof dwm)" ;;
	'hibernate') slock $ctl hibernate -i ;;
	'sleep') slock $ctl suspend -i ;;
	*) exit 1 ;;
esac

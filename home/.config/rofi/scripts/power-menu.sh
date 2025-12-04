#!/bin/sh

logout=$'\u200e\Uf0343 \u2068Logout\u2069'
shutdown=$'\u200e\Uf0425 \u2068Shut down\u2069'
reboot=$'\u200e\Uf0709 \u2068Reboot\u2069'

if [ -z "$1" ]; then
    echo -e "$shutdown"
    echo -e "$reboot"
    echo -e "$logout"
else
    if [ "$1" = "$shutdown" ]; then
        systemctl poweroff
    elif [ "$1" = "$reboot" ]; then
        systemctl reboot
    elif [ "$1" = "$logout" ]; then
        loginctl kill-session $XDG_SESSION_ID
    fi
fi


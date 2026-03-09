#!/bin/bash

LAYOUTS="us,ua"
OPTIONS="lv3:ralt_switch"

if [ "$1" = "status" ]; then
    current=$(setxkbmap -query | awk '/layout/{print $2}')
    if [ "$current" = "us" ]; then
        echo "🗽US"
    else
        echo "🌻UA"
    fi
    exit
fi

current=$(setxkbmap -query | awk '/layout/{print $2}')

if [ "$current" = "us" ]; then
    setxkbmap -layout ua -option "$OPTIONS"
else
    setxkbmap -layout us -option "$OPTIONS"
fi

pkill -RTMIN+1 dwmblocks


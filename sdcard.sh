#!/bin/sh
PATH1="/mnt/chromeos/removable/SD Card/now"
PATH2="/mnt/chromeos/removable/KINGSTON"

if [ ! -d "$PATH1" ]; then
    echo "⚠️ SD Card!"
else
    echo ""
fi

if [ -d "$PATH2" ]; then
    echo "KINGSTON"
else
    echo ""
fi

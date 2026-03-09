#!/bin/sh
capacity=$(cat /sys/class/power_supply/battery/capacity)
status=$(cat /sys/class/power_supply/battery/status)

if [ "$status" = "Discharging" ] ; then
    status_h="🔋"
elif [ "$status" = "Charging" ] ; then
    status_h="⚡"
else
    status_h="?"
fi

# Проверка уровня заряда и установка сообщения
if [ "$capacity" -lt 21 ]; then
    echo "⚠️ $status_h$capacity%" 
    if [ "$status" = "Discharging" ]; then
        notify-send "⚠️ Низький заряд батареї!" 
    fi    

elif [ "$capacity" -le 81 ]; then
    echo "$status_h$capacity%" 

else
    echo "$status_h$capacity%" 
    if [ "$status" != "Discharging" ]; then
        notify-send "⚡ >80% Можна вимкнути зарядний пристрій."
    fi 
fi

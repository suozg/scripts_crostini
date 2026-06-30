#!/bin/bash

EYES="
                    .:-=++++++++==-:.
                -=**+=-:........::=+**+=.
            .-**+-.   .=+*####*+=:    :=**+:
          :*#=:    .=#@@@@@@@@@@@@%+.    .-**=
        -#*-      -%@@@@@@@@@@@@@@@@%=      .+#=                                    EYE BREAK
      .*#:       =@@@@@@@@@@@@@@@@@@@@*       .+#-
     -%=        :@@@@@@@@@@@@@@@@@@@@@@-        :#+
    .@-         +@@@@@@@@@@@@@@@@@@@@@@*         .@-                        Look away from the screen
     #+         =@@@@@@@@@@@@@@@@@@@@@@*         -%.
     .#*.       .%@@@@@@@@@@@@@@@@@@@@%:        =%:
       %%+.      :%@@@@@@@@@@@@@@@@@@%-       -#*.
       %@@%+:     .*%@@@@@@@@@@@@@@@#:     .-#%:
       %@@@@@#=:    .+#%@@@@@@@@%#+:    .-*%@@%
       %@@%*+#@%#+-:   .:-=++=-:.   .:+#%@@@@@%.
       %@@*   *@@%=+**+==--:::--=+#%%@@@%**%@@%.
       =*+.   *@@#    .::----*@@@@@@@@@@=  +@@%.
              *@@%           -@@@+..+@@@=  :*#=
              +@@*           =@@@.  .%@@=
               ::            :#%*   .%@@=
                                    .@@@=
                                     =**."


LOCKFILE=/tmp/eyebreak.lock
exec 200>"$LOCKFILE"
flock -n 200 || exit 0

cleanup() {
    xsetroot -name ""
    pkill -RTMIN+10 dwmblocks
}
trap cleanup EXIT INT TERM

# Нескінченний цикл: чекаємо 1 годину -> показуємо вікно перерви на 5 хвилин
while true; do
    # 1. Очікування 60 хвилин (3600 секунд) перед перервою
    sleep 3600

    BREAK_TIME=300
    START=$(date +%s)

    # 2. Запуск циклу самої перерви (5 хвилин)
    while true; do
        NOW=$(date +%s)
        LEFT=$((BREAK_TIME - (NOW - START)))

        if [ "$LEFT" -le 0 ]; then
            break
        fi

        MIN=$((LEFT / 60))
        SEC=$((LEFT % 60))
        TIME_STR=$(printf "%02d:%02d" "$MIN" "$SEC")

        # Оновлюємо статус-бар dwm
        xsetroot -name "👁 Break: $TIME_STR"
        
        xmessage \
            -fn "fixed" \
            -title "Eye Break" \
            -center \
            -geometry 800x360 \
            -bg gray40 \
            -fg white \
            -buttons "" \
            -timeout 1 \
"$EYES

     Remaining: $TIME_STR" >/dev/null 2>&1

        # Оскільки xmessage працює рівно 1 секунду завдяки -timeout 1,
    done
    # Очищуємо статус-бар після закінчення перерви
    cleanup
done

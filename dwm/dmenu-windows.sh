#!/usr/bin/env bash

set -euo pipefail

FONT="monospace:size=12"

dmenu_cmd() {
    local prompt="$1"
    shift
    local opts=("-i" "-p" "$prompt" "-fn" "$FONT")

    if [[ -f "$HOME/.lightmode" ]]; then
        opts+=("-nb" "#eeeeee" "-nf" "#222222" "-sb" "#005577" "-sf" "#eeeeee")
    fi

    dmenu "${opts[@]}" "$@"
}

ids=$(xprop -root _NET_CLIENT_LIST 2>/dev/null | awk -F'#' '{print $2}' | tr ',' '\n' | tr -d ' ')

list=""
for id in $ids; do
    [[ -z "$id" ]] && continue
    title=$(xprop -id "$id" _NET_WM_NAME 2>/dev/null | awk -F'"' '{print $2}')
    [[ -z "$title" ]] && title=$(xprop -id "$id" WM_NAME 2>/dev/null | awk -F'"' '{print $2}')
    [[ -z "$title" ]] && continue

    desk=$(xprop -id "$id" _NET_WM_DESKTOP 2>/dev/null | awk -F'= ' '{print $2}' | tr -d ' ')
    if [[ -n "$desk" ]] && [[ "$desk" -ge 0 ]] && [[ "$desk" -le 8 ]] 2>/dev/null; then
        tag_label="[t$((desk + 1))]"
    else
        tag_label=""
    fi

    if [[ -n "$tag_label" ]]; then
        list="${list}${tag_label} ${title}\t${id}\n"
    else
        list="${list}${title}\t${id}\n"
    fi
done

[[ -z "$list" ]] && exit 0

chosen=$(printf '%b' "$list" | cut -f1 | dmenu_cmd "Вікна:" -l 12) || exit 0
[[ -z "$chosen" ]] && exit 0

win_id=$(printf '%b' "$list" | awk -F'\t' -v item="$chosen" '$1 == item { print $2; exit }')
[[ -n "$win_id" ]] && xsetroot -name "cmd:focus:${win_id}"

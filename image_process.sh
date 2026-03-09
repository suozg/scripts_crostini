#!/bin/bash

mkdir -p output

for img in *.jpg *.jpeg *.png; do
    [ -f "$img" ] || continue

    read width height <<< $(identify -format "%w %h" "$img")

    if [ "$width" -gt "$height" ]; then
        echo "Rotate $img"
        convert "$img" -rotate 90 -resize 1240x1754 \
        -gravity center -background white -extent 1240x1754 \
        output/"$img"
    else
        echo "Resize $img"
        convert "$img" -resize 1240x1754 \
        -gravity center -background white -extent 1240x1754 \
        output/"$img"
    fi
done



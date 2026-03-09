#!/bin/bash

mkdir -p resized

for f in *.jpg *.jpeg *.png *.webp; do
  [ -f "$f" ] || continue
  convert "$f" -resize 740x "resized/$f"
done


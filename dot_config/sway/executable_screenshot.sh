#!/bin/sh
set -eu

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"

geometry=$(slurp) || exit 0

file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
grim -g "$geometry" - | tee "$file" | wl-copy

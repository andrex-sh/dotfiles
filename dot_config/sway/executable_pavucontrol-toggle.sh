#!/bin/sh
# Waybar volume block's right-click: toggle pavucontrol - launch it if it's
# not running, close it if it already is (so right-clicking again makes it
# disappear instead of piling up duplicate windows).
set -eu

if pgrep -x pavucontrol >/dev/null 2>&1; then
    pkill -x pavucontrol
else
    pavucontrol &
fi

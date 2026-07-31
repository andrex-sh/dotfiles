#!/bin/sh
# usage: docked-workspaces.sh <primary-output> <secondary-output>
# workspaces 1-9 go to primary; workspace 10 is dedicated to secondary.
# Outputs may be given as a connector name (DP-3) or as a "make model serial"
# identifier, which contains spaces - hence the inner quotes below, so sway
# sees one output argument rather than several.
primary="$1"
secondary="$2"

for i in 1 2 3 4 5 6 7 8 9; do
    swaymsg "workspace number $i output \"$primary\""
    swaymsg "workspace number $i"
    swaymsg "move workspace to output \"$primary\""
done
swaymsg "workspace number 10 output \"$secondary\""
swaymsg "workspace number 10"
swaymsg "move workspace to output \"$secondary\""
swaymsg "workspace number 1"

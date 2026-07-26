#!/bin/sh
# i3status has no built-in keyboard-layout module (unlike i3blocks/py3status/
# waybar). This wraps it, injecting the current sway keyboard layout as an
# extra block on the front of each i3bar JSON update.
i3status | (
    read -r version_line; printf '%s\n' "$version_line"
    read -r array_start;   printf '%s\n' "$array_start"
    while read -r line; do
        prefix=""
        case "$line" in
            ,*) prefix=","; line="${line#,}" ;;
        esac
        idx=$(swaymsg -t get_inputs 2>/dev/null | jq '[.[] | select(.type=="keyboard")][0].xkb_active_layout_index // 0')
        case "$idx" in
            0) label="US" ;;
            1) label="BR" ;;
            *) label="?" ;;
        esac
        printf '%s' "$prefix"
        printf '%s' "$line" | jq -c --arg label "$label" '[{"name":"keyboard_layout","full_text":$label}] + .'
        printf '\n'
    done
)

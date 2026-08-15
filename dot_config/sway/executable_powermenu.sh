#!/bin/sh
# Session power menu, opened by waybar's custom/power module (see
# ~/.config/waybar/config).
set -eu

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a powermenu "$@" || true
}

# An empty $ctl means power-profiles-daemon isn't installed, and the profile
# entry is left out.
if command -v powerprofilesctl >/dev/null 2>&1; then
    ctl=powerprofilesctl
else
    ctl=''
fi

profile_menu() {
    # Matched against the three names the D-Bus API defines instead of
    # parsing the listing's shape, since that's undocumented.
    profiles="$("$ctl" list 2>/dev/null | grep -owE 'performance|balanced|power-saver' | awk '!seen[$0]++')" || true
    if [ "$(printf '%s\n' "$profiles" | grep -c .)" -lt 2 ]; then
        notify -u critical 'Power profile' "$ctl offers no profiles to switch between"
        return
    fi
    choice="$(printf '%s\n' "$profiles" | fuzzel --dmenu --prompt "Power profile ($("$ctl" get 2>/dev/null || echo unknown))> ")" || return
    [ -n "$choice" ] || return
    # No password prompt: power-profiles-daemon ships a polkit action that is
    # allow_active=yes, so an unlocked local session may switch freely.
    if "$ctl" set "$choice"; then
        notify 'Power profile' "Switched to $choice"
    else
        notify -u critical 'Power profile' "Failed to switch to $choice"
    fi
}

items="Lock
Log out
Suspend
Reboot
Power off"
[ -n "$ctl" ] && items="$items
Power profile"

choice="$(printf '%s\n' "$items" | fuzzel --dmenu --prompt 'Power> ')" || exit 0
case "$choice" in
    Lock) swaylock -f ;;
    'Log out') swaymsg exit ;;
    Suspend) systemctl suspend ;;
    Reboot) systemctl reboot ;;
    'Power off') systemctl poweroff ;;
    'Power profile') profile_menu ;;
    *) exit 0 ;;
esac

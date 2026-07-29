#!/bin/sh
# Session power menu, opened by waybar's custom/power module (see
# ~/.config/waybar/config).
set -eu

# One menu at a time: clicking the bar button again while the nag is already up
# is a no-op instead of stacking a second copy on top of the first. The lock is
# held by fd 9 for as long as swaynag runs, and released when it exits.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/sway-powermenu.lock"
flock -n 9 || exit 0

# swaynag lays buttons out right-to-left: the *last* -B/-Z flag ends up
# leftmost, and the first one sits next to the dismiss button. Hence the
# reversed order below, which reads "Lock  Log out  Suspend  Power off" on
# screen. -Z (dismiss, no terminal) closes the nag as it fires the action;
# swaynag double-forks the command, so it survives swaynag exiting.
swaynag -t warning \
    -m 'Session' \
    -s 'Cancel' \
    -Z 'Power off' 'systemctl poweroff' \
    -Z 'Suspend' 'systemctl suspend' \
    -Z 'Log out' 'swaymsg exit' \
    -Z 'Lock' 'swaylock -f'

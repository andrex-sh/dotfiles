#!/bin/sh
# Session power menu, opened by waybar's custom/power module (see
# ~/.config/waybar/config). A swaynag button can only run a shell command, so
# the nested power-profile menu is this same script re-invoking itself:
#
#   powermenu.sh                  session menu
#   powermenu.sh profile          power-profile menu
#   powermenu.sh profile <name>   switch to <name>, then report via mako
set -eu

# swaynag runs button actions through `sh -c`, so the action strings below get
# re-parsed by a second shell: $HOME is deliberately left unexpanded and quoted
# for that second pass, the same way waybar's on-click invokes this script.
self='"$HOME/.config/sway/powermenu.sh"'

# tlp-pd implements the same D-Bus API as power-profiles-daemon, and tlpctl the
# same list/get/set verbs with the same three profile names - so which stack is
# installed (apt gets ppd, pacman gets tlp) only changes the binary name. An
# empty $ctl means neither is present and the profile button is left out.
if command -v powerprofilesctl >/dev/null 2>&1; then
    ctl=powerprofilesctl
elif command -v tlpctl >/dev/null 2>&1; then
    ctl=tlpctl
else
    ctl=''
fi

# A machine without libnotify still switches profiles, it just does it silently
# rather than taking the switch down with it. No -t/-u styling here:
# ~/.config/mako/config owns timeouts and urgency presentation.
notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a powermenu "$@" || true
}

session_menu() {
    # swaynag lays buttons out right-to-left: the *last* -B/-Z flag ends up
    # leftmost, and the first one sits next to the dismiss button. Hence the
    # reversed order below, which reads "Power profile  Lock  Log out  Suspend
    # Power off" on screen - harmless on the left, irreversible on the right.
    # -Z (dismiss, no terminal) closes the nag as it fires the action; swaynag
    # double-forks the command, so it survives swaynag exiting.
    set -- -t warning \
        -m 'Session' \
        -s 'Cancel' \
        -Z 'Power off' 'systemctl poweroff' \
        -Z 'Suspend' 'systemctl suspend' \
        -Z 'Log out' 'swaymsg exit' \
        -Z 'Lock' 'swaylock -f'
    # -Z rather than -B for the submenu too: -B would leave this nag on screen
    # underneath the second one, and keep its swaynag holding the lock fd open
    # for as long as it stayed up.
    if [ -n "$ctl" ]; then
        set -- "$@" -Z 'Power profile' "$self profile"
    fi
    swaynag "$@"
}

profile_menu() {
    # Asked for rather than hardcoded, because the offered set is hardware
    # dependent - a machine exposing neither a platform_profile nor a CPU
    # driver gets balanced only. Matched against the three names the D-Bus API
    # defines instead of parsing the listing's shape, since ppd and tlpctl
    # format it differently and tlpctl's layout is undocumented.
    profiles="$("$ctl" list 2>/dev/null | grep -owE 'performance|balanced|power-saver' | awk '!seen[$0]++')" || true
    # One profile is not a choice, and none means the daemon is not answering.
    if [ "$(printf '%s\n' "$profiles" | grep -c .)" -lt 2 ]; then
        notify -u critical 'Power profile' "$ctl offers no profiles to switch between"
        exit 1
    fi
    # Same right-to-left rule as above, so prepend while walking the daemon's
    # own order (performance first) and the buttons come out reading
    # "performance  balanced  power-saver" on screen.
    set --
    for p in $profiles; do
        set -- -Z "$p" "$self profile $p" "$@"
    done
    swaynag -t warning \
        -m "Power profile - currently $("$ctl" get 2>/dev/null || echo unknown)" \
        -s 'Cancel' \
        "$@"
}

set_profile() {
    # No password prompt: both daemons ship a polkit action that is
    # allow_active=yes, so an unlocked local session may switch freely.
    if "$ctl" set "$1"; then
        notify 'Power profile' "Switched to $1"
    else
        notify -u critical 'Power profile' "Failed to switch to $1"
    fi
}

case "${1:-}" in
    '')
        # One menu at a time: clicking the bar button again while the nag is
        # already up is a no-op instead of stacking a second copy on top of the
        # first. The lock is held by fd 9 for as long as swaynag runs, and
        # released when it exits. Only this top-level entry takes it - swaynag
        # starts the nested invocation *before* exiting, so a second `flock -n`
        # would lose the race against its own parent and silently exit 0. The
        # nested calls inherit fd 9 instead, which keeps the lock held for the
        # whole interaction without ever re-acquiring it.
        exec 9>"${XDG_RUNTIME_DIR:-/tmp}/sway-powermenu.lock"
        flock -n 9 || exit 0
        session_menu
        ;;
    profile)
        [ -n "$ctl" ] || exit 0
        if [ $# -ge 2 ]; then set_profile "$2"; else profile_menu; fi
        ;;
    *)
        echo "usage: ${0##*/} [profile [name]]" >&2
        exit 2
        ;;
esac

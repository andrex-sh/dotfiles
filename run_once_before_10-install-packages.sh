#!/bin/sh
set -eu

nerd_font_version="v3.4.0"
nerd_font_sha256="ef552a3e638f25125c6ad4c51176a6adcdce295ab1d2ffacf0db060caf8c1582"

install_pacman() {
    pkgs="sway swaybg swaylock waybar foot fuzzel lxqt-policykit kanshi mako libnotify grim slurp wl-clipboard playerctl brightnessctl libpulse ttf-jetbrains-mono-nerd yazi tmux network-manager-applet pavucontrol xdg-desktop-portal xdg-desktop-portal-wlr pipewire wireplumber"

    # tlp is the better stack where it's available, and tlp-pd gives it the
    # same D-Bus API power-profiles-daemon exposes, so ~/.config/sway/
    # powermenu.sh switches profiles identically on both distros. Not pulling
    # in tlp-rdw: it's optional and would drag along TLP's advice to mask
    # systemd-rfkill, which is more than this repo should do unasked.
    #
    # tlp conflicts with power-profiles-daemon, so on a machine that already
    # has ppd (a GNOME install would) the unattended `pacman -S --noconfirm`
    # below either aborts the whole transaction or silently uninstalls ppd -
    # neither is a decision a bootstrap script should be making. Skip the two
    # packages instead; ppd alone still drives the power menu perfectly well.
    if pacman -Qi power-profiles-daemon >/dev/null 2>&1; then
        echo "power-profiles-daemon is installed; it conflicts with tlp." >&2
        echo "Skipping tlp/tlp-pd. To switch: sudo pacman -Rs power-profiles-daemon, then re-run." >&2
    else
        pkgs="$pkgs tlp tlp-pd"
    fi

    missing=""
    for p in $pkgs; do
        pacman -Qi "$p" >/dev/null 2>&1 || missing="$missing $p"
    done
    if [ -n "$missing" ]; then
        echo "Installing (pacman):$missing"
        sudo pacman -S --needed --noconfirm $missing
    else
        echo "All pacman packages already present, skipping."
    fi

    # Arch enables neither on install, unlike Debian's power-profiles-daemon.
    for unit in tlp.service tlp-pd.service; do
        # `systemctl cat` fails on an unknown unit, which is how we skip this
        # when the conflict check above left tlp uninstalled.
        if systemctl cat "$unit" >/dev/null 2>&1 &&
            ! systemctl is-enabled --quiet "$unit"; then
            sudo systemctl enable --now "$unit"
        fi
    done
}

install_apt() {
    # power-profiles-daemon rather than tlp here: tlp-pd needs TLP >= 1.9 and
    # Debian/Ubuntu are still on 1.6, so tlp would mean no profile switching.
    # The .deb enables the service itself, so there is nothing to enable below.
    pkgs="sway swaybg swaylock waybar foot fuzzel lxqt-policykit kanshi mako-notifier libnotify-bin grim slurp wl-clipboard playerctl brightnessctl pulseaudio-utils power-profiles-daemon wget tar fontconfig ca-certificates tmux network-manager-gnome pavucontrol xdg-desktop-portal xdg-desktop-portal-wlr pipewire wireplumber"
    missing=""
    for p in $pkgs; do
        dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
    done
    if [ -n "$missing" ]; then
        echo "Installing (apt):$missing"
        sudo apt-get update
        sudo apt-get install -y $missing
    else
        echo "All apt packages already present, skipping."
    fi

    if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
        echo "JetBrainsMono Nerd Font already installed, skipping."
    else
        echo "Installing JetBrainsMono Nerd Font..."
        mkdir -p "$HOME/.local/share/fonts"
        tmpfile="$(mktemp --suffix=.tar.xz)"
        wget -O "$tmpfile" "https://github.com/ryanoasis/nerd-fonts/releases/download/${nerd_font_version}/JetBrainsMono.tar.xz"
        echo "$nerd_font_sha256  $tmpfile" | sha256sum -c -
        tar -xf "$tmpfile" -C "$HOME/.local/share/fonts/"
        rm -f "$tmpfile"
        fc-cache -f -v
    fi

    if command -v yazi >/dev/null 2>&1; then
        echo "yazi already installed, skipping."
    else
        echo "Installing yazi via snap..."
        command -v snap >/dev/null 2>&1 || { sudo apt-get update; sudo apt-get install -y snapd; }
        sudo snap install yazi --classic
    fi
}

if command -v pacman >/dev/null 2>&1; then
    install_pacman
elif command -v apt >/dev/null 2>&1; then
    install_apt
else
    echo "Neither pacman nor apt found; install packages manually." >&2
    exit 1
fi

#!/bin/sh
set -eu

nerd_font_version="v3.4.0"
nerd_font_sha256="ef552a3e638f25125c6ad4c51176a6adcdce295ab1d2ffacf0db060caf8c1582"

install_pacman() {
    pkgs="sway swaybg swaylock swayidle waybar foot fuzzel lxqt-policykit kanshi mako grim slurp wl-clipboard playerctl brightnessctl libpulse ttf-jetbrains-mono-nerd yazi tmux network-manager-applet pavucontrol xdg-desktop-portal xdg-desktop-portal-wlr pipewire wireplumber"
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
}

install_apt() {
    pkgs="sway swaybg swaylock swayidle waybar foot fuzzel lxqt-policykit kanshi mako-notifier grim slurp wl-clipboard playerctl brightnessctl pulseaudio-utils wget tar fontconfig ca-certificates tmux network-manager-gnome pavucontrol xdg-desktop-portal xdg-desktop-portal-wlr pipewire wireplumber"
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

#!/bin/sh
# One-time system setup for a fresh machine: packages, the ly greeter,
# bluetooth (disabled by this package's own preset, so needs an explicit
# enable), and kanshi's service (the kanshi package ships no unit of its own
# - the one tracked at dot_config/systemd/user/kanshi.service is hand-authored).
# Re-runs if this file's content changes (chezmoi hashes it).
set -eu

sudo pacman -S --needed \
    ly sway waybar swaync swaylock swaybg foot fuzzel kanshi \
    power-profiles-daemon xorg-xwayland lxqt-policykit nm-connection-editor \
    network-manager-applet bluez bluez-utils blueman \
    playerctl brightnessctl grim slurp wl-clipboard pavucontrol dolphin \
    ttf-jetbrains-mono-nerd pipewire pipewire-pulse wireplumber libnotify \
    xdg-desktop-portal xdg-desktop-portal-wlr zenity rocm-smi-lib gsimplecal \
    paru brave-bin

sudo systemctl enable ly@tty2.service
sudo systemctl enable bluetooth.service

systemctl --user daemon-reload
systemctl --user enable kanshi.service

#!/bin/sh
# One-time system setup for a fresh machine: packages, the ly greeter,
# bluetooth (disabled by this package's own preset, so needs an explicit
# enable), docker (service + group, so docker works without sudo after
# re-login), and kanshi's service (the kanshi package ships no unit of its
# own - the one tracked at dot_config/systemd/user/kanshi.service is
# hand-authored).
# Re-runs if this file's content changes (chezmoi hashes it).
#
# File manager is Thunar (GTK), not a KDE app - this is a bare Sway box with
# no Plasma session, and KDE apps need KService/ksycoca infrastructure
# (menu-spec files, kded) that isn't set up here. GTK/xdg-mime resolves
# associations directly, no such infrastructure needed.
set -eu

sudo pacman -S --needed \
    ly sway waybar swaync swaylock swaybg foot fuzzel kanshi \
    power-profiles-daemon xorg-xwayland lxqt-policykit nm-connection-editor \
    network-manager-applet bluez bluez-utils blueman \
    playerctl brightnessctl grim slurp wl-clipboard pavucontrol \
    thunar tumbler exo gvfs mpv libreoffice-fresh \
    ttf-jetbrains-mono-nerd pipewire pipewire-pulse wireplumber libnotify \
    xdg-desktop-portal xdg-desktop-portal-wlr zenity rocm-smi-lib gsimplecal lazygit \
    paru brave-bin docker docker-compose

paru -S --needed qimgv

sudo systemctl enable ly@tty2.service
sudo systemctl enable bluetooth.service
sudo systemctl enable docker.service
sudo usermod -aG docker "$USER"

systemctl --user daemon-reload
systemctl --user enable kanshi.service

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

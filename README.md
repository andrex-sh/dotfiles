# dotfiles

[sway](https://swaywm.org/) desktop setup, managed with [chezmoi](https://www.chezmoi.io/). This repo *is* the chezmoi source directory.

## Tracked

sway, waybar, swaync, swaylock, foot, fuzzel, the sway power-menu/screenshot/hwstatus scripts, kanshi's workspace-assignment helper + service, nvim, ly (package + `ly@tty2.service` + `/etc/ly/config.ini`, autologin as `andrex` into `sway`), docker (package + `docker-compose` + `docker.service`, user added to the `docker` group), and `cachyos-gaming-meta` + `steam` (`multilib`, already enabled by CachyOS).

`/etc/ly/config.ini` lives at `ly/config.ini` in this repo (chezmoi only manages files under `$HOME`) and is installed by `run_onchange_ly-config.sh.tmpl`, which reruns whenever that file changes.

Wifi/VPN and bluetooth are handled by `nm-applet` and `blueman-applet` tray applets. `nm-connection-editor` is tracked for importing a VPN profile: `nmcli connection import type openvpn file foo.ovpn` or `nm-connection-editor`.

## Not tracked

- `~/.config/kanshi/config` - monitor layout is per-machine, write it by hand (see `man kanshi` and `dot_config/kanshi/executable_docked-workspaces.sh`). Each profile needs `exec sh -c 'pkill waybar; exec waybar'` too, or waybar keeps the pre-kanshi layout at login (kanshi's `graphical-session.target` start races sway's own `exec waybar`).

## Bootstrap on a new machine

```sh
curl -fsSL https://raw.githubusercontent.com/andrex-sh/dotfiles/main/bootstrap.sh | sh
```

`bootstrap.sh` clones this repo to `~/Projects/dotfiles`, installs chezmoi, and runs `chezmoi init --apply` - equivalent to running these by hand:

```sh
git clone https://github.com/andrex-sh/dotfiles.git ~/Projects/dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
~/.local/bin/chezmoi init --source ~/Projects/dotfiles --apply
```

First `apply` runs `run_once_install.sh`: installs packages, enables `ly@tty2.service`/`bluetooth.service`/`docker.service`/`kanshi.service`, adds you to the `docker` group. Answer the sudo prompt, then reboot (also picks up the `docker` group membership). If tty2 already has a `getty@tty2.service` enabled, `sudo systemctl disable getty@tty2` first.

Then hand-write `~/.config/kanshi/config` for that machine.

## Daily workflow

```sh
chezmoi diff      # preview
chezmoi apply     # write
git add -A && git commit -m "..." && git push
```

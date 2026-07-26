# dotfiles

Portable [sway](https://swaywm.org/) desktop setup, managed with [chezmoi](https://www.chezmoi.io/).
This repo *is* the chezmoi source directory.

## Bootstrap on a new machine

```sh
git clone git@github.com:andrex-sh/dotfiles.git ~/projects/dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
~/.local/bin/chezmoi init --source ~/projects/dotfiles --apply
```

Answer the prompts, then reload sway (`$mod+Shift+c`) or re-login.

`~/.config/kanshi/config` is **not** managed by chezmoi — it's local/manual per machine, since monitor arrangements (outputs, positions, rotation) vary too much per machine to template well. Write one by hand after bootstrapping; see `man kanshi` and `dot_config/kanshi/executable_docked-workspaces.sh` for the workspace-assignment helper it can call.

## Daily workflow

Edit files under `~/projects/dotfiles`, then:

```sh
chezmoi diff      # preview what would change
chezmoi apply     # write it to your home directory
git add -A && git commit -m "..." && git push
```

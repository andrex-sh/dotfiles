# dotfiles

Portable [sway](https://swaywm.org/) desktop setup, managed with [chezmoi](https://www.chezmoi.io/).
This repo *is* the chezmoi source directory.

## Bootstrap on a new machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)"
~/.local/bin/chezmoi init --source ~/projects/dotfiles --apply
```

Answer the prompts, then reload sway (`$mod+Shift+c`) or re-login.

## Daily workflow

Edit files under `~/projects/dotfiles`, then:

```sh
chezmoi diff      # preview what would change
chezmoi apply     # write it to your home directory
git add -A && git commit -m "..." && git push
```

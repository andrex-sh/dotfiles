#!/bin/sh
# One-command fresh-machine setup:
#   curl -fsSL https://raw.githubusercontent.com/andrex-sh/dotfiles/main/bootstrap.sh | sh
set -eu

repo="https://github.com/andrex-sh/dotfiles.git"
dest="$HOME/projects/dotfiles"

if [ ! -d "$dest" ]; then
    git clone "$repo" "$dest"
fi

sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
"$HOME/.local/bin/chezmoi" init --source "$dest" --apply

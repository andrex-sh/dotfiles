# ~/.profile

# Firefox wayland compatibility
export MOZ_ENABLE_WAYLAND=1
export XDG_SESSION_TYPE=wayland

# Default editors
export EDITOR="nvim"
export VISUAL="code"

# Hyprshot
export HYPRSHOT_DIR="$HOME/screenshots"

if [ -f "$HOME/.zshrc" ]; then
    . "$HOME/.zshrc"
fi

. "$HOME/.local/bin/env"


#!/bin/sh
set -e

# Needed dirs
if [ ! -d $HOME/screenshots ]; then
    mkdir $HOME/screenshots
fi

sudo pacman -S --needed --noconfirm git

# === Config ===
REPO_URL="https://github.com/andrex-sh/dotfiles.git"
REPO_DIR="$HOME/dotfiles"

# === Step 1: Clone repo ===
if [[ -d "$REPO_DIR" ]]; then
    echo "[*] Repo already exists at $REPO_DIR, pulling latest..."
    git -C "$REPO_DIR" pull
else
    echo "[*] Cloning repo..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

# === Step 2: Install packages from Archfile ===
cd "$REPO_DIR"
if [[ -f "$REPO_DIR/Archfile" ]]; then
    echo "[*] Installing packages from Archfile..."
    sudo pacman -Syu --needed - < $REPO_DIR/Archfile
else
    echo "[!] Archfile not found in repo!"
    exit 1
fi

# Install paru aur helper
git clone https://aur.archlinux.org/paru.git $HOME/paru
cd $HOME/paru
makepkg -si

# Install packages from Aurfile
cd "$REPO_DIR"
if [[ -f "$REPO_DIR/Aurfile" ]]; then
    echo "[*] Installing packages from Aurfile..."
    paru -S --needed - < $REPO_DIR/Aurfile
else
    echo "[!] Aurfile not found in repo!"
    exit 1
fi

# Switch to zsh
chsh -s $(which zsh)

# Set remote url to ssh
REPO_URL="git@github.com:andrex-sh/dotfiles.git"
echo "[*] Changing remote url to $REPO_URL"
cd $REPO_DIR && git remote set-url origin $REPO_URL

# Run stow
cd $REPO_DIR && stow --adopt -v git hyprland kitty profile rofi waybar zsh

# Enable units
xargs -a $REPO_DIR/user_units.txt -n1 systemctl --user enable --now
xargs -a $REPO_DIR/sys_units.txt -n1 systemctl enable

# Disable tty2 for ly
systemctl disable getty@tty2.service

echo "[*] Done."

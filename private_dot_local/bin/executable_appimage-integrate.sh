#!/bin/sh
# Scans ~/Applications for *.AppImage files and creates a matching .desktop
# entry (with the app's real name/icon, extracted from inside the AppImage
# itself rather than guessed from the filename) in
# ~/.local/share/applications. Run by hand whenever you add or remove an
# AppImage - no background watcher, no daemon.
set -eu

appimage_dir="$HOME/Applications"
desktop_dir="$HOME/.local/share/applications"
icon_dir="$HOME/.local/share/icons"

mkdir -p "$appimage_dir" "$desktop_dir" "$icon_dir"

for appimage in "$appimage_dir"/*.AppImage; do
    [ -e "$appimage" ] || continue
    chmod +x "$appimage"

    name="$(basename "$appimage" .AppImage)"
    desktop_file="$desktop_dir/appimage-$name.desktop"

    if [ -e "$desktop_file" ]; then
        continue
    fi

    workdir="$(mktemp -d)"

    if ! (cd "$workdir" && "$appimage" --appimage-extract >/dev/null 2>&1); then
        rm -rf "$workdir"
        echo "warning: could not extract $appimage, skipping" >&2
        continue
    fi

    src_desktop="$(find "$workdir/squashfs-root" -maxdepth 1 -name '*.desktop' | head -1)"
    if [ -z "$src_desktop" ]; then
        rm -rf "$workdir"
        echo "warning: no .desktop found inside $appimage, skipping" >&2
        continue
    fi

    display_name="$(awk -F= '/^Name=/{print $2; exit}' "$src_desktop")"
    [ -n "$display_name" ] || display_name="$name"

    icon_name="$(awk -F= '/^Icon=/{print $2; exit}' "$src_desktop")"
    icon_path=""
    if [ -n "$icon_name" ]; then
        src_icon="$(find "$workdir/squashfs-root" -maxdepth 1 -iname "$icon_name.*" | head -1)"
        if [ -n "$src_icon" ]; then
            icon_path="$icon_dir/appimage-$name.${src_icon##*.}"
            cp "$src_icon" "$icon_path"
        fi
    fi

    {
        printf '[Desktop Entry]\n'
        printf 'Type=Application\n'
        printf 'Name=%s\n' "$display_name"
        printf 'Exec=%s %%U\n' "$appimage"
        if [ -n "$icon_path" ]; then
            printf 'Icon=%s\n' "$icon_path"
        fi
        printf 'Terminal=false\n'
    } > "$desktop_file"

    rm -rf "$workdir"
    echo "integrated: $display_name"
done

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$desktop_dir" || true
fi

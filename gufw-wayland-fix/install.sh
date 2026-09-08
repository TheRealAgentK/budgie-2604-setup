#!/bin/bash
# Install the gufw Wayland wrapper for the current user.
set -eu

here=$(cd "$(dirname "$0")" && pwd)

bin_dst="$HOME/.local/bin/gufw"
desktop_dst="$HOME/.local/share/applications/gufw.desktop"
system_desktop="/usr/share/applications/gufw.desktop"

mkdir -p "$(dirname "$bin_dst")" "$(dirname "$desktop_dst")"

install -m 0755 "$here/bin/gufw" "$bin_dst"
echo "installed $bin_dst"

if [ -r "$system_desktop" ]; then
    sed "s|^Exec=gufw$|Exec=$bin_dst|" "$system_desktop" > "$desktop_dst"
else
    # Fall back to the copy kept in the repo.
    sed "s|^Exec=.*/\.local/bin/gufw$|Exec=$bin_dst|" \
        "$here/applications/gufw.desktop" > "$desktop_dst"
fi
echo "installed $desktop_dst"

command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$(dirname "$desktop_dst")" 2>/dev/null || true

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "warning: $HOME/.local/bin is not on PATH; the menu item still works via the absolute Exec= path" ;;
esac

echo "done. Launch 'Firewall Configuration' or run: gufw"

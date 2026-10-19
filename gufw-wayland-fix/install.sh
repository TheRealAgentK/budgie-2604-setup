#!/bin/bash
# Install the gufw Wayland wrapper for the current user.
#
# "./install.sh --check" reports state and changes nothing.
set -eu

here=$(cd "$(dirname "$0")" && pwd)

bin_dst="$HOME/.local/bin/gufw"
desktop_dst="$HOME/.local/share/applications/gufw.desktop"
system_desktop="/usr/share/applications/gufw.desktop"

CHECK=0
[ "${1-}" = "--check" ] && CHECK=1

# The menu entry: the system one with Exec= pointed at the wrapper, or the copy
# kept in the repo if gufw's own entry is missing.
desktop_content() {
    if [ -r "$system_desktop" ]; then
        sed "s|^Exec=gufw$|Exec=$bin_dst|" "$system_desktop"
    else
        sed "s|^Exec=.*/\.local/bin/gufw$|Exec=$bin_dst|" "$here/applications/gufw.desktop"
    fi
}

if [ "$CHECK" = 1 ]; then
    if [ -f "$bin_dst" ] && cmp -s "$here/bin/gufw" "$bin_dst"; then
        echo "$bin_dst: current"
    else
        echo "$bin_dst: WOULD install"
    fi
    if [ -f "$desktop_dst" ] && [ "$(desktop_content)" = "$(cat "$desktop_dst")" ]; then
        echo "$desktop_dst: current"
    else
        echo "$desktop_dst: WOULD install"
    fi
    exit 0
fi

mkdir -p "$(dirname "$bin_dst")" "$(dirname "$desktop_dst")"

install -m 0755 "$here/bin/gufw" "$bin_dst"
echo "installed $bin_dst"

desktop_content > "$desktop_dst"
echo "installed $desktop_dst"

command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$(dirname "$desktop_dst")" 2>/dev/null || true

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "warning: $HOME/.local/bin is not on PATH; the menu item still works via the absolute Exec= path" ;;
esac

echo "done. Launch 'Firewall Configuration' or run: gufw"

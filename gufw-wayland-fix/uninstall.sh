#!/bin/bash
# Remove the gufw Wayland wrapper for the current user.
set -eu

bin_dst="$HOME/.local/bin/gufw"
desktop_dst="$HOME/.local/share/applications/gufw.desktop"

for f in "$bin_dst" "$desktop_dst"; do
    if [ -e "$f" ]; then
        rm -f "$f"
        echo "removed $f"
    else
        echo "not present: $f"
    fi
done

command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$(dirname "$desktop_dst")" 2>/dev/null || true

echo "done. 'Firewall Configuration' now uses the system entry again"
echo "(still broken on Wayland - that is expected)."

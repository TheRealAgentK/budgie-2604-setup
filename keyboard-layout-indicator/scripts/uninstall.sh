#!/bin/bash
# Optional uninstaller for keyboard-layout-indicator.
#
# Removes ONLY this project's own user-level files and stops a running instance
# started from the installed path. Never uses sudo. Never touches
# /usr/local/bin/xkb-monitor (it is a general-purpose tool).
#
# Usage:
#   ./uninstall.sh [--dry-run]
set -eu

DRY=0
for a in "$@"; do
    case "$a" in
        --dry-run) DRY=1 ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "unknown option: $a" >&2; exit 2 ;;
    esac
done

DST_BIN="$HOME/.local/bin/keyboard-layout-indicator"
DST_SHARE="$HOME/.local/share/keyboard-layout-indicator"
DST_DESKTOP="$HOME/.config/autostart/keyboard-layout-indicator.desktop"

run() {
    if [ "$DRY" = 1 ]; then printf 'DRY  %s\n' "$*"; else printf ' RUN %s\n' "$*"; "$@"; fi
}

echo "keyboard-layout-indicator uninstaller${DRY:+ (dry-run)}"

# stop a running instance (match the installed path only)
if pgrep -f "$DST_BIN" >/dev/null 2>&1; then
    run pkill -f "$DST_BIN"
else
    echo "  no running instance"
fi

for path in "$DST_DESKTOP" "$DST_BIN"; do
    if [ -e "$path" ]; then run rm -f "$path"; else echo "  not present: $path"; fi
done

if [ -e "$DST_SHARE" ]; then run rm -rf "$DST_SHARE"; else echo "  not present: $DST_SHARE"; fi

echo
echo "Left untouched on purpose:"
echo "  /usr/local/bin/xkb-monitor   (remove manually if nothing else needs it)"
echo "  apt packages (python3-gi, gir1.2-ayatanaappindicator3-0.1, build deps)"

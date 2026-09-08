#!/bin/bash
# Optional installer for keyboard-layout-indicator.
#
# Installs ONLY the project's own user-level files:
#   ~/.local/bin/keyboard-layout-indicator
#   ~/.local/share/keyboard-layout-indicator/icons/{kbd-en,kbd-de}.svg
#   ~/.config/autostart/keyboard-layout-indicator.desktop   (with --autostart)
#
# It does NOT:
#   - use sudo
#   - install apt packages
#   - build or install xkb-monitor        (see docs/INSTALL.md parts 1-2)
#   - touch anything outside $HOME/.local and $HOME/.config/autostart
#
# Usage:
#   ./install.sh [--dry-run] [--autostart]
#
#   --dry-run     print what would happen, change nothing
#   --autostart   also write the ~/.config/autostart entry
set -eu

DRY=0
AUTOSTART=0
for a in "$@"; do
    case "$a" in
        --dry-run)   DRY=1 ;;
        --autostart) AUTOSTART=1 ;;
        -h|--help)   sed -n '2,20p' "$0"; exit 0 ;;
        *) echo "unknown option: $a" >&2; exit 2 ;;
    esac
done

HERE=$(cd "$(dirname "$0")/.." && pwd)          # the component directory
SRC_BIN="$HERE/src/keyboard-layout-indicator"
SRC_EN="$HERE/icons/kbd-en.svg"
SRC_DE="$HERE/icons/kbd-de.svg"
TMPL="$HERE/packaging/keyboard-layout-indicator.desktop.example"

DST_BIN="$HOME/.local/bin/keyboard-layout-indicator"
DST_ICONS="$HOME/.local/share/keyboard-layout-indicator/icons"
DST_DESKTOP="$HOME/.config/autostart/keyboard-layout-indicator.desktop"

for f in "$SRC_BIN" "$SRC_EN" "$SRC_DE" "$TMPL"; do
    [ -f "$f" ] || { echo "missing repo file: $f" >&2; exit 1; }
done

run() {
    if [ "$DRY" = 1 ]; then
        printf 'DRY  %s\n' "$*"
    else
        printf ' RUN %s\n' "$*"
        "$@"
    fi
}

echo "keyboard-layout-indicator installer${DRY:+ (dry-run)}"
echo "  NOTE: apt packages and xkb-monitor are NOT handled here - see docs/INSTALL.md"
echo

run install -D -m 0755 "$SRC_BIN" "$DST_BIN"
run install -D -m 0644 "$SRC_EN" "$DST_ICONS/kbd-en.svg"
run install -D -m 0644 "$SRC_DE" "$DST_ICONS/kbd-de.svg"

if [ "$AUTOSTART" = 1 ]; then
    if [ "$DRY" = 1 ]; then
        printf 'DRY  write %s with Exec=%s\n' "$DST_DESKTOP" "$DST_BIN"
    else
        mkdir -p "$(dirname "$DST_DESKTOP")"
        sed "s|@EXEC@|$DST_BIN|" "$TMPL" > "$DST_DESKTOP"
        printf ' RUN wrote %s\n' "$DST_DESKTOP"
    fi
else
    echo "  (skipping autostart; pass --autostart to add it)"
fi

echo
echo "Next:"
echo "  - ensure /usr/local/bin/xkb-monitor exists (docs/INSTALL.md part 2)"
echo "  - ensure the Budgie panel has a Status Notifier / AppIndicator applet"
echo "  - test:  /usr/bin/python3 \"$DST_BIN\""

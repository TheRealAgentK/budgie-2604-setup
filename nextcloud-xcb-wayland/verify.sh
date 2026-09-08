#!/bin/bash
# Read-only. Makes no changes.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
DESKTOP="$HOME/.config/autostart/Nextcloud.desktop"
REF="$HERE/reference/Nextcloud.desktop"
APPIMAGE_GLOB="/opt/Nextcloud-*-x86_64.AppImage"

echo "== live autostart entry =="
if [ -r "$DESKTOP" ]; then
    grep -E '^Exec=' "$DESKTOP" || echo "  (no Exec= line?)"
    if cmp -s "$REF" "$DESKTOP"; then echo "  [ ok ] identical to reference/Nextcloud.desktop"
    else echo "  [info] differs from reference/Nextcloud.desktop:"; diff -u "$REF" "$DESKTOP" || true; fi
else
    echo "  [MISS] $DESKTOP not present"
fi

echo
echo "== AppImage =="
for f in $APPIMAGE_GLOB; do
    [ -e "$f" ] && echo "  present: $f ($(stat -c '%U:%G %a' "$f"))" || echo "  [MISS] no $APPIMAGE_GLOB"
done

echo
echo "== startbudgielabwc Qt platform handling (read-only) =="
grep -n 'QT_QPA_PLATFORM' /usr/bin/startbudgielabwc 2>&1 || echo "  (not found)"

echo
echo "== repo wrapper (not installed on this machine by design) =="
echo "  $HERE/scripts/nextcloud-xcb"
command -v nextcloud-xcb >/dev/null 2>&1 && echo "  note: a 'nextcloud-xcb' IS on PATH: $(command -v nextcloud-xcb)" \
    || echo "  not on PATH (expected)"

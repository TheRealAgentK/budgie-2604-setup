#!/bin/bash
# Read-only hibernate verification. Makes no changes. Never uses sudo.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
LIVE=/etc/polkit-1/rules.d/10-enable-hibernate.rules
REPO="$HERE/10-enable-hibernate.rules"

echo "== CanHibernate (desktop user) =="
busctl call org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager CanHibernate 2>&1
echo "   expect: s \"yes\""

echo
echo "== resume config (do not modify) =="
grep -o 'resume[^ ]*' /proc/cmdline || echo "   (no resume* on kernel cmdline)"
echo "-- swapon --show --"
swapon --show 2>&1

echo
echo "== polkit rule =="
if [ -r "$LIVE" ]; then
    if diff -u "$REPO" "$LIVE" >/dev/null 2>&1; then
        echo "   [ ok ] live file readable and identical to repo copy"
    else
        echo "   [WARN] live file readable and DIFFERS from repo copy:"
        diff -u "$REPO" "$LIVE" || true
    fi
else
    echo "   [info] $LIVE not readable without sudo (expected)."
    echo "          Repo copy is the handoff's known-working content."
    echo "          To compare: sudo diff -u \"$REPO\" \"$LIVE\""
fi

echo
echo "== legacy .pkla (should be absent) =="
pkla=/etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla
if [ -e "$pkla" ]; then echo "   [WARN] $pkla exists - handoff says it was removed"
else echo "   [info] not visible (dir may be root-only; handoff records it removed)"; fi

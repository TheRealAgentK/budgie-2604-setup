#!/bin/bash
# Read-only. Makes no changes.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
LIVE=/etc/sysctl.d/60-inotify.conf
REPO="$HERE/60-inotify.conf"

if [ -r "$LIVE" ]; then
    echo "live file : $LIVE  ($(stat -c '%U:%G %a' "$LIVE"))"
    if cmp -s "$REPO" "$LIVE"; then echo "  [ ok ] identical to repo copy"
    else echo "  [WARN] differs from repo copy:"; diff -u "$REPO" "$LIVE" || true; fi
else
    echo "  [MISS] $LIVE not present/readable"
fi
echo
echo "running value:"
sysctl fs.inotify.max_user_watches 2>&1
echo "  expect: fs.inotify.max_user_watches = 1000000"

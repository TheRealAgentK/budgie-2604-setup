#!/bin/bash
# Reverse swayidle-dbus-fix/install.sh.
#
#   - removes ~/.local/bin/swayidle (only if it is the patched build)
#   - restarts running swayidle processes so they go back to /usr/bin/swayidle
#   - "--purge" also removes the build cache
set -eu

here=$(cd "$(dirname "$0")" && pwd)
. "$here/lib/restart.sh"

VERSION=1.9.0
cache="${XDG_CACHE_HOME:-$HOME/.cache}/budgie-2604-setup/swayidle-$VERSION-patched"
built="$cache/src/build/swayidle"
dst="$HOME/.local/bin/swayidle"

say() { printf '  %s\n' "$*"; }

echo "[1/3] $dst"
if [ ! -f "$dst" ]; then
    say "not installed"
elif [ -x "$built" ] && ! cmp -s "$built" "$dst"; then
    say "is not the patched build from $cache - left alone"
    exit 1
else
    rm -f "$dst"
    say "removed"
fi

echo "[2/3] running swayidle processes"
while read -r pid exe; do
    [ -n "$pid" ] || continue
    case "$exe" in
        "$dst"*) restart_swayidle "$pid" && say "restarted pid $pid" ;;
        *) say "pid $pid uses $exe" ;;
    esac
done < <(user_swayidles)

echo "[3/3] build cache"
if [ "${1-}" = --purge ] && [ -d "$cache" ]; then
    rm -rf "$cache"
    say "removed $cache"
else
    say "kept (use --purge to remove)"
fi

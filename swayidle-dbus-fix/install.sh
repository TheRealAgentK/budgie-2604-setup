#!/bin/bash
# Install swayidle 1.9.0 + upstream fix a959e59 as ~/.local/bin/swayidle.
#
# swayidle 1.9.0 (Ubuntu 26.04's package) can strand logind's PrepareForSleep
# signal in sd-bus's internal queue and then handles every later sleep signal
# one step late: suspend waits 30 s for its inhibitor and the before-sleep lock
# never runs. Upstream fixed it after 1.9.0; see README.md.
#
# ~/.local/bin is ahead of /usr/bin on PATH for labwc, budgie-daemon and the
# labwc autostart, so Budgie's swayidle and the resume-display-on listener both
# pick this binary up. The swayidle package is not touched.
#
# Applies, idempotently:
#   1. builds the patched binary in ~/.cache/budgie-2604-setup/ (once)
#   2. installs it as ~/.local/bin/swayidle
#   3. restarts running swayidle processes that still use /usr/bin/swayidle
#
# "./install.sh --check" reports state and changes nothing.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
. "$here/lib/restart.sh"
TS=$(date +%Y%m%d-%H%M%S)

VERSION=1.9.0
PKG_EXPECTED=1.9.0-1
URL="https://github.com/swaywm/swayidle/archive/refs/tags/v$VERSION.tar.gz"
SHA256=161f5827b8c79bc486a472d27690e98d75da6615bb2dee9f24393cbbb13af656
PATCHES=("$here"/patches/*.patch)

cache="${XDG_CACHE_HOME:-$HOME/.cache}/budgie-2604-setup/swayidle-$VERSION-patched"
built="$cache/src/build/swayidle"
dst="$HOME/.local/bin/swayidle"

CHECK=0
[ "${1-}" = "--check" ] && CHECK=1

say() { printf '  %s\n' "$*"; }

# --- 0. dependencies ---------------------------------------------------------
echo "[0/3] dependencies"
missing=""
for c in curl patch meson ninja cc pkg-config wayland-scanner sha256sum; do
    command -v "$c" >/dev/null 2>&1 || missing="$missing $c"
done
for p in wayland-client wayland-server wayland-protocols libsystemd; do
    pkg-config --exists "$p" 2>/dev/null || missing="$missing $p(dev)"
done
if [ -n "$missing" ]; then
    say "missing:$missing"
    say "sudo apt install meson ninja-build build-essential pkg-config libwayland-dev wayland-protocols libsystemd-dev"
    exit 1
fi
say "build tools present"
pkg=$(dpkg-query -W -f='${Version}' swayidle 2>/dev/null || echo none)
if [ "$pkg" = "$PKG_EXPECTED" ]; then
    say "packaged swayidle $pkg (the affected version)"
else
    say "NOTE: packaged swayidle is now $pkg, not $PKG_EXPECTED."
    say "      If it contains upstream commit a959e59, run ./uninstall.sh instead."
fi

# --- 1. build ----------------------------------------------------------------
echo "[1/3] patched build ($cache)"
if [ -x "$built" ]; then
    say "already built"
elif [ "$CHECK" = 1 ]; then
    say "WOULD download v$VERSION, verify SHA-256, apply ${#PATCHES[@]} patch(es), build"
else
    rm -rf "$cache"; mkdir -p "$cache/src"
    curl -fsSL -o "$cache/swayidle-$VERSION.tar.gz" "$URL"
    echo "$SHA256  $cache/swayidle-$VERSION.tar.gz" | sha256sum -c --quiet \
        || { say "SHA-256 mismatch for $URL - not building"; exit 1; }
    tar -xzf "$cache/swayidle-$VERSION.tar.gz" -C "$cache/src" --strip-components=1
    for p in "${PATCHES[@]}"; do
        patch -d "$cache/src" -p1 --quiet < "$p"
        say "applied $(basename "$p")"
    done
    meson setup "$cache/src/build" "$cache/src" --buildtype=release \
        -Dman-pages=disabled -Dlogind=enabled -Dlogind-provider=systemd \
        -Dzsh-completions=false -Dbash-completions=false -Dfish-completions=false \
        >"$cache/build.log" 2>&1 \
      && ninja -C "$cache/src/build" >>"$cache/build.log" 2>&1 \
      || { say "build failed - see $cache/build.log"; exit 1; }
    say "built"
fi

# --- 2. install ----------------------------------------------------------------
echo "[2/3] $dst"
if [ -f "$dst" ] && [ -x "$built" ] && cmp -s "$built" "$dst"; then
    say "already current"
elif [ "$CHECK" = 1 ]; then
    say "WOULD install"
else
    mkdir -p "$(dirname "$dst")"
    [ -f "$dst" ] && { cp "$dst" "$dst.bak-$TS"; say "backup $dst.bak-$TS"; }
    install -m 0755 "$built" "$dst"
    say "installed"
fi
case "$(command -v swayidle)" in
    "$dst") ;;
    *) [ "$CHECK" = 1 ] || say "WARNING: 'swayidle' on this shell's PATH is $(command -v swayidle)" ;;
esac

# --- 3. running instances ----------------------------------------------------
echo "[3/3] running swayidle processes"
n=0
while read -r pid exe; do
    [ -n "$pid" ] || continue
    if [ "$exe" = "$dst" ]; then
        say "pid $pid already uses the patched binary"
    elif [ "$CHECK" = 1 ]; then
        say "WOULD restart pid $pid ($exe)"
    else
        restart_swayidle "$pid" && say "restarted pid $pid (was $exe)"
        n=$((n + 1))
    fi
done < <(user_swayidles)
if [ "$n" -gt 0 ]; then
    sleep 3
    user_swayidles | sed 's/^/  now: pid /'
fi

[ "$CHECK" = 0 ] && { echo; echo "done. Verify:  for p in \$(pgrep -x swayidle); do readlink /proc/\$p/exe; done"; }
exit 0

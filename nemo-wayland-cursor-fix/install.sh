#!/bin/bash
# Native-Wayland Nemo horizontal column-resize cursor fix.
#
# Applies, idempotently:
#   1. builds  src/nemo-gtk3-cursor-fix.c
#   2. installs /usr/local/lib/libnemo-gtk3-cursor-fix.so
#   3. registers a dpkg-divert of /usr/bin/nemo -> /usr/bin/nemo.real
#   4. installs the LD_PRELOAD wrapper as /usr/bin/nemo
#
# Nemo stays on the Wayland GDK backend. GDK_BACKEND is never set.
# Re-running makes no change if the machine is already configured.
# "./install.sh --check" reports state and changes nothing.
set -eu

SRC=$(cd "$(dirname "$0")" && pwd)

LIB_SRC="$SRC/src/nemo-gtk3-cursor-fix.c"
LIB_DST="/usr/local/lib/libnemo-gtk3-cursor-fix.so"
WRAPPER_SRC="$SRC/nemo-wrapper.sh"
BIN="/usr/bin/nemo"
BIN_REAL="/usr/bin/nemo.real"

CHECK=0
[ "${1-}" = "--check" ] && CHECK=1
say() { printf '  %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

diverted() { [ "$(dpkg-divert --truename "$BIN" 2>/dev/null)" = "$BIN_REAL" ]; }
# functional comparison: ignore comments (except #!), blank lines, trailing space
norm() {
    sed 's/[[:space:]]*$//' "$1" 2>/dev/null \
        | grep -vE '^[[:space:]]*#([^!]|$)' \
        | grep -vE '^[[:space:]]*$'
}
same_script() { [ -f "$2" ] && [ "$(norm "$1")" = "$(norm "$2")" ]; }

# --- sanity: refuse to run on a half-configured system ------------------------
if [ -e "$BIN_REAL" ] && ! diverted; then
    die "$BIN_REAL exists but no dpkg-divert is registered for $BIN. Resolve by hand before continuing."
fi
if diverted && [ ! -e "$BIN_REAL" ]; then
    die "$BIN is diverted to $BIN_REAL but that file is missing. Run: sudo dpkg-divert --remove --rename --divert $BIN_REAL $BIN"
fi

# --- 1 + 2. build and install the shim --------------------------------------
echo "[1/3] shim library"
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
if ! command -v gcc >/dev/null 2>&1; then
    if [ "$CHECK" = 1 ]; then say "gcc not installed (needed to build the shim)"; else die "gcc not installed: sudo apt-get install -y build-essential"; fi
else
    gcc -shared -fPIC -O2 -o "$build/lib.so" "$LIB_SRC" -ldl
    if [ -f "$LIB_DST" ] && cmp -s "$build/lib.so" "$LIB_DST"; then
        say "$LIB_DST already current"
    elif [ "$CHECK" = 1 ]; then
        say "WOULD install $LIB_DST ($( [ -e "$LIB_DST" ] && echo differs || echo missing ))"
    else
        sudo install -D -m 0644 "$build/lib.so" "$LIB_DST"
        say "installed $LIB_DST"
    fi
fi

# --- 3. dpkg-divert -----------------------------------------------------------
echo "[2/3] dpkg-divert $BIN -> $BIN_REAL"
if diverted; then
    say "already registered"
elif [ "$CHECK" = 1 ]; then
    say "WOULD run: dpkg-divert --add --rename --divert $BIN_REAL $BIN"
else
    sudo dpkg-divert --add --rename --divert "$BIN_REAL" "$BIN"
    say "registered (package binary moved to $BIN_REAL)"
fi

# --- 4. wrapper -------------------------------------------------------------------
echo "[3/3] wrapper at $BIN"
if same_script "$WRAPPER_SRC" "$BIN"; then
    say "already current"
elif [ "$CHECK" = 1 ]; then
    say "WOULD install wrapper at $BIN"
elif ! diverted; then
    die "refusing to write $BIN while it is not diverted (would overwrite the package binary)"
else
    sudo install -m 0755 "$WRAPPER_SRC" "$BIN"
    say "installed"
fi

if [ "$CHECK" = 0 ]; then
    echo
    echo "done. Restart Nemo:  nemo -q ; then reopen it."
    echo "Test: resize a detail-view column (cursor appears); drag a file into Brave (works)."
fi

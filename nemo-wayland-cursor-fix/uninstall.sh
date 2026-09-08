#!/bin/bash
# Reverse nemo-wayland-cursor-fix/install.sh: restore the packaged /usr/bin/nemo.
set -eu

LIB_DST="/usr/local/lib/libnemo-gtk3-cursor-fix.so"
BIN="/usr/bin/nemo"
BIN_REAL="/usr/bin/nemo.real"

say() { printf '  %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
diverted() { [ "$(dpkg-divert --truename "$BIN" 2>/dev/null)" = "$BIN_REAL" ]; }

nemo -q 2>/dev/null || true

echo "[1/3] wrapper + dpkg-divert"
if diverted; then
    [ -e "$BIN_REAL" ] || die "$BIN is diverted but $BIN_REAL is missing - cannot safely restore. Fix by hand."
    # our wrapper sits at $BIN; remove it so --rename can move the real binary back
    if [ -f "$BIN" ]; then
        sudo rm -f "$BIN"
        say "removed wrapper $BIN"
    fi
    sudo dpkg-divert --remove --rename --divert "$BIN_REAL" "$BIN"
    say "divert removed; packaged binary restored to $BIN"
else
    say "no divert registered - leaving $BIN untouched"
fi

echo "[2/3] shim library"
if [ -e "$LIB_DST" ]; then
    sudo rm -f "$LIB_DST"
    say "removed $LIB_DST"
else
    say "not present"
fi

echo "[3/3] verify"
if [ "$(dpkg-divert --truename "$BIN" 2>/dev/null)" = "$BIN" ] && [ -x "$BIN" ] && ! [ -e "$BIN_REAL" ]; then
    say "OK - $BIN is the packaged binary, no divert, no shim"
else
    say "WARNING: unexpected final state - check: dpkg-divert --list | grep nemo ; ls -l $BIN $BIN_REAL"
fi

echo
echo "done. Restart Nemo to pick up the packaged binary."

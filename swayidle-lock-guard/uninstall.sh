#!/bin/bash
# Reverse swayidle-lock-guard/install.sh.
#
#   - stops the guard (Budgie's swayidle is left running as it is)
#   - removes the marked block from the labwc autostart (rest of file untouched)
#   - removes ~/.local/bin/swayidle-lock-guard
set -eu

TS=$(date +%Y%m%d-%H%M%S)

bin_dst="$HOME/.local/bin/swayidle-lock-guard"
autostart="$HOME/.config/budgie-desktop/labwc/autostart"
START="# >>> budgie-2604-setup:swayidle-lock-guard >>>"
END="# <<< budgie-2604-setup:swayidle-lock-guard <<<"

say() { printf '  %s\n' "$*"; }

echo "[1/3] guard process"
if pgrep -u "$(id -u)" -f "^/bin/bash $bin_dst" >/dev/null 2>&1; then
    pkill -u "$(id -u)" -f "^/bin/bash $bin_dst" || true
    say "stopped"
else
    say "not running"
fi

echo "[2/3] labwc autostart managed block"
if [ -f "$autostart" ] && grep -qF "$START" "$autostart"; then
    cp "$autostart" "$autostart.bak-$TS"
    awk -v s="$START" -v e="$END" '
        $0==s {skip=1; next}
        skip && $0==e {skip=0; next}
        skip {next}
        {print}
    ' "$autostart.bak-$TS" > "$autostart"
    # drop a trailing blank line left behind
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$autostart"
    say "removed (backup $autostart.bak-$TS)"
else
    say "no managed block present"
fi

echo "[3/3] $bin_dst"
if [ -f "$bin_dst" ]; then
    rm -f "$bin_dst"
    say "removed"
else
    say "not installed"
fi

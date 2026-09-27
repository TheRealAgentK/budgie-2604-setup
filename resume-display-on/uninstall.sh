#!/bin/bash
# Reverse resume-display-on/install.sh.
#
#   - removes the marked block from the labwc autostart (rest of file untouched)
#   - stops the listener loop and its after-resume swayidle; Budgie's own
#     swayidle is left alone
#   - removes ~/.local/bin/resume-display-on-listener
set -eu

TS=$(date +%Y%m%d-%H%M%S)

bin_dst="$HOME/.local/bin/resume-display-on-listener"
autostart="$HOME/.config/budgie-desktop/labwc/autostart"
START="# >>> budgie-2604-setup:resume-display-on >>>"
END="# <<< budgie-2604-setup:resume-display-on <<<"

say() { printf '  %s\n' "$*"; }

echo "[1/3] labwc autostart managed block"
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

echo "[2/3] after-resume listener"
if pgrep -u "$(id -u)" -f "^/bin/sh $bin_dst|^swayidle after-resume" >/dev/null 2>&1; then
    # the loop first, so it cannot respawn the listener
    pkill -u "$(id -u)" -f "^/bin/sh $bin_dst" || true
    pkill -u "$(id -u)" -f "^swayidle after-resume" || true
    say "stopped"
else
    say "not running"
fi

echo "[3/3] $bin_dst"
if [ -f "$bin_dst" ]; then
    rm -f "$bin_dst"
    say "removed"
else
    say "not installed"
fi

#!/bin/bash
# Reverse display-scaling/install.sh.
#
#   - removes the marked "kanshi &" block from the labwc autostart (rest of file
#     is left untouched)
#   - removes ~/.config/kanshi/config if it is the one this repo installed
#   - resets slickSDDM General/scale to 1.0 (the theme default)
#
# The kanshi package is left installed. Remove it yourself with
# "sudo apt remove kanshi" if nothing else needs it.
set -eu

SRC=$(cd "$(dirname "$0")" && pwd)
TS=$(date +%Y%m%d-%H%M%S)

autostart="$HOME/.config/budgie-desktop/labwc/autostart"
kcfg="$HOME/.config/kanshi/config"
START="# >>> budgie-2604-setup:display-scaling >>>"
END="# <<< budgie-2604-setup:display-scaling <<<"

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
    # drop a leading blank line left behind
    sed -i '1{/^$/d}' "$autostart"
    say "removed (backup $autostart.bak-$TS)"
else
    say "no managed block present"
fi

echo "[2/3] $kcfg"
if [ ! -e "$kcfg" ]; then
    say "not present"
elif cmp -s "$SRC/config/kanshi.config" "$kcfg"; then
    rm -f "$kcfg"
    rmdir "$(dirname "$kcfg")" 2>/dev/null || true
    say "removed"
else
    say "left in place - differs from the repo copy, so it may be hand-edited"
fi

echo "[3/3] slickSDDM General/scale"
if command -v slicksddm-customize >/dev/null 2>&1; then
    cur=$(slicksddm-customize --get "General/scale" 2>/dev/null | tr -d '[:space:]' || true)
    if [ "$cur" = "1.0" ] || [ "$cur" = "1" ]; then
        say "already at default ($cur)"
    else
        say "-> slicksddm-customize --set General/scale=1.0  (was: $cur, needs sudo)"
        sudo slicksddm-customize --set "General/scale=1.0"
    fi
else
    say "slicksddm-customize not found - skipping"
fi

if pgrep -x kanshi >/dev/null 2>&1; then
    pkill -x kanshi 2>/dev/null || true
    echo
    echo "kanshi stopped. The output keeps its current mode until next login,"
    echo "after which the compositor default (2880x1800) applies."
fi

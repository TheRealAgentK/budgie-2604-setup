#!/bin/bash
# Reverse charge-limit-alert/install.sh.
#
#   - stops and disables charge-guard.service, removes the unit and the script
#   - keeps ~/.config/budgie-2604-setup/charge-guard.conf (your settings);
#     "./uninstall.sh --purge" moves it to a .bak-<timestamp> copy as well
set -eu

TS=$(date +%Y%m%d-%H%M%S)

bin_dst="$HOME/.local/bin/charge-guard"
conf_dst="${XDG_CONFIG_HOME:-$HOME/.config}/budgie-2604-setup/charge-guard.conf"
unit_dst="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/charge-guard.service"

PURGE=0
[ "${1-}" = "--purge" ] && PURGE=1

say() { printf '  %s\n' "$*"; }

echo "[1/4] charge-guard.service"
if systemctl --user is-enabled charge-guard.service >/dev/null 2>&1 \
   || systemctl --user is-active charge-guard.service >/dev/null 2>&1; then
    systemctl --user disable --now charge-guard.service >/dev/null 2>&1 || true
    say "stopped and disabled"
else
    say "not enabled or running"
fi

echo "[2/4] $unit_dst"
if [ -f "$unit_dst" ]; then
    rm -f "$unit_dst"
    systemctl --user daemon-reload
    say "removed"
else
    say "not installed"
fi

echo "[3/4] $bin_dst"
if [ -f "$bin_dst" ]; then
    rm -f "$bin_dst"
    say "removed"
else
    say "not installed"
fi

echo "[4/4] $conf_dst"
if [ ! -f "$conf_dst" ]; then
    say "not present"
elif [ "$PURGE" = 1 ]; then
    mv "$conf_dst" "$conf_dst.bak-$TS"
    say "moved to $conf_dst.bak-$TS"
else
    say "kept (use --purge to remove)"
fi

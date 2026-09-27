#!/bin/bash
# Install charge-guard as a systemd user service.
#
# Applies, idempotently:
#   1. ~/.local/bin/charge-guard - the watcher
#   2. ~/.config/budgie-2604-setup/charge-guard.conf - settings; created from
#      the repo default only if missing, never overwritten
#   3. ~/.config/systemd/user/charge-guard.service - enabled and started;
#      restarted if the script or unit changed
#
# Re-running makes no changes if the machine is already configured.
# "./install.sh --check" reports state and changes nothing.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
TS=$(date +%Y%m%d-%H%M%S)

bin_src="$here/bin/charge-guard"
bin_dst="$HOME/.local/bin/charge-guard"
conf_src="$here/config/charge-guard.conf"
conf_dst="${XDG_CONFIG_HOME:-$HOME/.config}/budgie-2604-setup/charge-guard.conf"
unit_src="$here/systemd/charge-guard.service"
unit_dst="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/charge-guard.service"

CHECK=0
[ "${1-}" = "--check" ] && CHECK=1

say() { printf '  %s\n' "$*"; }
changed=0

# install_file SRC DST MODE - copy if different, backing up an existing DST
install_file() {
    if [ -f "$2" ] && cmp -s "$1" "$2"; then
        say "already current"
    elif [ "$CHECK" = 1 ]; then
        say "WOULD install"
    else
        mkdir -p "$(dirname "$2")"
        [ -f "$2" ] && { cp "$2" "$2.bak-$TS"; say "backup $2.bak-$TS"; }
        install -m "$3" "$1" "$2"
        say "installed"
        changed=1
    fi
}

# --- 0. dependencies ---------------------------------------------------------
echo "[0/4] dependencies"
command -v systemctl >/dev/null 2>&1 || { say "systemctl missing"; exit 1; }
if command -v notify-send >/dev/null 2>&1; then
    say "notify-send present"
else
    say "notify-send missing - warnings only reach the journal (apt install libnotify-bin)"
fi
"$bin_src" --once >/dev/null || { say "charge-guard cannot read the battery on this machine"; exit 1; }
say "battery readable: $("$bin_src" --once)"

# --- 1. script ---------------------------------------------------------------
echo "[1/4] $bin_dst"
install_file "$bin_src" "$bin_dst" 0755

# --- 2. settings -------------------------------------------------------------
echo "[2/4] $conf_dst"
if [ -f "$conf_dst" ]; then
    if cmp -s "$conf_src" "$conf_dst"; then say "present (repo default)"
    else say "present (customised - left alone)"; fi
elif [ "$CHECK" = 1 ]; then
    say "WOULD create from repo default"
else
    mkdir -p "$(dirname "$conf_dst")"
    install -m 0644 "$conf_src" "$conf_dst"
    say "created from repo default"
fi

# --- 3. user service ---------------------------------------------------------
echo "[3/4] $unit_dst"
install_file "$unit_src" "$unit_dst" 0644

echo "[4/4] charge-guard.service"
enabled=$(systemctl --user is-enabled charge-guard.service 2>/dev/null || true)
active=$(systemctl --user is-active charge-guard.service 2>/dev/null || true)
if [ "$CHECK" = 1 ]; then
    [ "$enabled" = enabled ] && say "enabled" || say "WOULD enable"
    [ "$active" = active ] && say "running" || say "WOULD start"
else
    systemctl --user daemon-reload
    [ "$enabled" = enabled ] || { systemctl --user enable charge-guard.service >/dev/null 2>&1; say "enabled"; }
    if [ "$active" != active ]; then
        systemctl --user start charge-guard.service; say "started"
    elif [ "$changed" = 1 ]; then
        systemctl --user restart charge-guard.service; say "restarted (script or unit changed)"
    else
        say "running"
    fi
fi

[ "$CHECK" = 0 ] && { echo; echo "done. Verify:  systemctl --user status charge-guard; charge-guard --once"; }
exit 0

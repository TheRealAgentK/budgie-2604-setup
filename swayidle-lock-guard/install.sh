#!/bin/bash
# Install swayidle-lock-guard for the Budgie/labwc session.
#
# Applies, idempotently:
#   1. ~/.local/bin/swayidle-lock-guard - the guard script
#   2. ~/.config/budgie-desktop/labwc/autostart - a marked block starting it
#   3. starts it for the current session if it is not already running
#
# Re-running makes no changes if the machine is already configured.
# "./install.sh --check" reports state and changes nothing.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
TS=$(date +%Y%m%d-%H%M%S)

bin_src="$here/bin/swayidle-lock-guard"
bin_dst="$HOME/.local/bin/swayidle-lock-guard"
autostart="$HOME/.config/budgie-desktop/labwc/autostart"
START="# >>> budgie-2604-setup:swayidle-lock-guard >>>"
END="# <<< budgie-2604-setup:swayidle-lock-guard <<<"
BLOCK="$START
# Lock and restart Budgie's swayidle if it stops handling suspend (managed by budgie-2604-setup/swayidle-lock-guard)
\"$bin_dst\" &
$END"

CHECK=0
[ "${1-}" = "--check" ] && CHECK=1

say() { printf '  %s\n' "$*"; }

# --- 0. dependencies ---------------------------------------------------------
echo "[0/3] dependencies"
missing=""
for c in swayidle journalctl systemd-cat flock setsid; do
    command -v "$c" >/dev/null 2>&1 || missing="$missing $c"
done
if [ -n "$missing" ]; then
    say "missing:$missing"
    exit 1
fi
if ! journalctl --lines=1 -t systemd-logind >/dev/null 2>&1 \
   || [ -z "$(journalctl --lines=1 --output=cat -t systemd-logind 2>/dev/null)" ]; then
    say "cannot read systemd-logind's journal as $(id -un) - needs group adm or systemd-journal"
    exit 1
fi
say "present; logind journal readable"

# --- 1. script ---------------------------------------------------------------
echo "[1/3] $bin_dst"
if [ -f "$bin_dst" ] && cmp -s "$bin_src" "$bin_dst"; then
    say "already current"
elif [ "$CHECK" = 1 ]; then
    say "WOULD install"
else
    mkdir -p "$(dirname "$bin_dst")"
    [ -f "$bin_dst" ] && cp "$bin_dst" "$bin_dst.bak-$TS"
    install -m 0755 "$bin_src" "$bin_dst"
    say "installed"
fi

# --- 2. labwc autostart managed block ----------------------------------------
echo "[2/3] $autostart"
mkdir -p "$(dirname "$autostart")"
export BLOCK
if [ -f "$autostart" ] && grep -qF "$START" "$autostart"; then
    new=$(awk -v s="$START" -v e="$END" '
        $0==s {print ENVIRON["BLOCK"]; skip=1; next}
        skip && $0==e {skip=0; next}
        skip {next}
        {print}
    ' "$autostart")
    if [ "$new" = "$(cat "$autostart")" ]; then
        say "managed block already current"
    elif [ "$CHECK" = 1 ]; then
        say "WOULD refresh managed block"
    else
        cp "$autostart" "$autostart.bak-$TS"
        printf '%s\n' "$new" > "$autostart"
        say "managed block refreshed (backup $autostart.bak-$TS)"
    fi
elif [ "$CHECK" = 1 ]; then
    say "WOULD add managed block"
else
    if [ -s "$autostart" ]; then
        cp "$autostart" "$autostart.bak-$TS"
        printf '\n%s\n' "$BLOCK" >> "$autostart"
        say "managed block added (backup $autostart.bak-$TS)"
    else
        printf '%s\n' "$BLOCK" > "$autostart"
        say "managed block added"
    fi
fi

# --- 3. guard for the current session ----------------------------------------
echo "[3/3] guard process"
running=$(pgrep -u "$(id -u)" -f "^/bin/bash $bin_dst" | head -1 || true)
if [ -n "$running" ]; then
    say "already running (pid $running)"
elif [ "$CHECK" = 1 ]; then
    say "WOULD start it for this session"
elif [ -z "${WAYLAND_DISPLAY-}" ]; then
    say "not in a Wayland session - it starts at next login"
else
    setsid -f "$bin_dst" </dev/null >/dev/null 2>&1
    say "started for this session"
fi

[ "$CHECK" = 0 ] && { echo; echo "done. Verify:  pgrep -af swayidle-lock-guard; journalctl -t swayidle-lock-guard"; }
exit 0

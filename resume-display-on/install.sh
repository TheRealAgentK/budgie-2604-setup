#!/bin/bash
# Turn the display back on after suspend/resume in the Budgie/labwc session.
#
# Budgie's swayidle (hardcoded in budgie-daemon) switches outputs off after
# 5 min idle ("wlopm --off *") and, on battery, suspends after 20 min. Its
# "resume wlopm --on *" only fires on idle activity, not on system resume, so
# waking from that suspend leaves the panel dark while the machine runs.
#
# budgie-daemon also runs "killall swayidle" at startup, which kills a plain
# listener started from the autostart, so the listener runs in a respawn loop.
#
# Applies, idempotently:
#   1. ~/.local/bin/resume-display-on-listener - keeps a second swayidle that
#      only runs "wlopm --on *" after every resume alive for the session
#   2. ~/.config/budgie-desktop/labwc/autostart - a marked block starting it
#   3. starts it now if it is not already running
#
# Re-running makes no changes if the machine is already configured.
# "./install.sh --check" reports state and changes nothing.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
TS=$(date +%Y%m%d-%H%M%S)

bin_src="$here/bin/resume-display-on-listener"
bin_dst="$HOME/.local/bin/resume-display-on-listener"
autostart="$HOME/.config/budgie-desktop/labwc/autostart"
START="# >>> budgie-2604-setup:resume-display-on >>>"
END="# <<< budgie-2604-setup:resume-display-on <<<"
BLOCK="$START
# Re-enable display outputs after suspend/resume (managed by budgie-2604-setup/resume-display-on)
\"$bin_dst\" &
$END"

CHECK=0
[ "${1-}" = "--check" ] && CHECK=1
bin_changed=0

say() { printf '  %s\n' "$*"; }

# --- 0. dependencies ---------------------------------------------------------
echo "[0/3] dependencies"
missing=""
for c in swayidle wlopm flock; do command -v "$c" >/dev/null 2>&1 || missing="$missing $c"; done
if [ -n "$missing" ]; then
    say "missing:$missing - install them first (they ship with Budgie on labwc)"
    exit 1
fi
say "swayidle, wlopm and flock present"

# --- 1. listener script ------------------------------------------------------
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
    bin_changed=1
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

# --- 3. listener loop for the current session -------------------------------
echo "[3/3] after-resume listener"
loop=$(pgrep -u "$(id -u)" -f "^/bin/sh $bin_dst" | head -1 || true)
if [ -n "$loop" ] && [ "$bin_changed" = 1 ] && [ -n "${WAYLAND_DISPLAY-}" ]; then
    # the running loop is the old script: replace it and its listener
    pkill -u "$(id -u)" -f "^/bin/sh $bin_dst" || true
    pkill -u "$(id -u)" -f "^swayidle after-resume" || true
    sleep 0.5
    setsid -f "$bin_dst" </dev/null >/dev/null 2>&1
    say "respawn loop restarted with the updated script"
elif [ -n "$loop" ]; then
    say "respawn loop already running (pid $loop)"
elif [ "$CHECK" = 1 ]; then
    say "WOULD start the respawn loop for this session"
elif [ -z "${WAYLAND_DISPLAY-}" ]; then
    say "not in a Wayland session - it starts at next login"
else
    # replace a bare listener left by an older install
    pkill -u "$(id -u)" -f "^swayidle after-resume" || true
    setsid -f "$bin_dst" </dev/null >/dev/null 2>&1
    say "respawn loop started for this session"
fi

[ "$CHECK" = 0 ] && { echo; echo "done. Verify:  pgrep -af 'resume-display-on-listener|^swayidle after-resume'"; }
exit 0

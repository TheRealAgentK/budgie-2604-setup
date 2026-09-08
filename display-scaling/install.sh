#!/bin/bash
# Display resolution / scaling consistency for the Budgie/labwc Wayland session.
#
# Applies, idempotently:
#   1. kanshi (apt) - reapplies the Wayland output profile on login/hotplug/resume
#   2. ~/.config/kanshi/config          - eDP-1 -> 2304x1440@90Hz, scale 1.0
#   3. ~/.config/budgie-desktop/labwc/autostart - a clearly marked "kanshi &" block
#   4. slickSDDM General/scale = 1.25   - login screen stays at native 2880x1800
#
# Re-running makes no changes if the machine is already configured.
# "./install.sh --check" reports state and changes nothing.
set -eu

SRC=$(cd "$(dirname "$0")" && pwd)
TS=$(date +%Y%m%d-%H%M%S)

OUTPUT="eDP-1"
SDDM_SCALE="1.25"

autostart="$HOME/.config/budgie-desktop/labwc/autostart"
kcfg="$HOME/.config/kanshi/config"
START="# >>> budgie-2604-setup:display-scaling >>>"
END="# <<< budgie-2604-setup:display-scaling <<<"
BLOCK="$START
# Keep laptop display at 2304x1440 @ 90 Hz, scale 1.0  (managed by budgie-2604-setup/display-scaling)
kanshi &
$END"

CHECK=0
[ "${1-}" = "--check" ] && CHECK=1

say()  { printf '  %s\n' "$*"; }
need_sudo() { say "-> $*"; [ "$CHECK" = 1 ] && { say "   (skipped: --check)"; return 1; }; return 0; }

# --- 1. kanshi package -------------------------------------------------------
echo "[1/4] kanshi package"
if command -v kanshi >/dev/null 2>&1; then
    say "already installed ($(dpkg-query -W -f='${Version}' kanshi 2>/dev/null || echo present))"
else
    if need_sudo "apt-get install -y kanshi"; then
        sudo apt-get update -qq
        sudo apt-get install -y kanshi
    fi
fi

# --- 2. ~/.config/kanshi/config -------------------------------------------------
echo "[2/4] $kcfg"
mkdir -p "$(dirname "$kcfg")"
if [ -f "$kcfg" ] && cmp -s "$SRC/config/kanshi.config" "$kcfg"; then
    say "already current"
elif [ "$CHECK" = 1 ]; then
    say "WOULD ${kcfg:+write} $kcfg"
elif [ -f "$kcfg" ]; then
    cp "$kcfg" "$kcfg.bak-$TS"; cp "$SRC/config/kanshi.config" "$kcfg"
    say "updated (backup $kcfg.bak-$TS)"
else
    cp "$SRC/config/kanshi.config" "$kcfg"; say "installed"
fi

# --- 3. labwc autostart managed block ----------------------------------------
echo "[3/4] $autostart"
mkdir -p "$(dirname "$autostart")"
[ -f "$autostart" ] || { [ "$CHECK" = 1 ] || : > "$autostart"; }
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
    if grep -qE '^[[:space:]]*kanshi[[:space:]]*&[[:space:]]*$' "$autostart" 2>/dev/null; then
        say "WOULD migrate the existing unmanaged 'kanshi &' line into a managed block"
    else
        say "WOULD add managed block"
    fi
else
    [ -f "$autostart" ] && cp "$autostart" "$autostart.bak-$TS"
    body=$(grep -vE '^[[:space:]]*kanshi[[:space:]]*&[[:space:]]*$' "$autostart" 2>/dev/null \
           | grep -vE '^[[:space:]]*#.*(kanshi|2304x1440)' || true)
    {
        if [ -n "$body" ]; then printf '%s\n\n' "$body"; fi
        printf '%s\n' "$BLOCK"
    } > "$autostart"
    say "managed block added${autostart:+ (backup $autostart.bak-$TS)}"
fi

# --- 4. slickSDDM login-screen scale ---------------------------------------------
echo "[4/4] slickSDDM General/scale"
if ! command -v slicksddm-customize >/dev/null 2>&1; then
    say "slicksddm-customize not found - skipping (login-screen scale unmanaged)"
else
    cur=$(slicksddm-customize --get "General/scale" 2>/dev/null | tr -d '[:space:]' || true)
    if [ "$cur" = "$SDDM_SCALE" ]; then
        say "already $SDDM_SCALE"
    elif need_sudo "slicksddm-customize --set General/scale=$SDDM_SCALE  (was: ${cur:-unset})"; then
        sudo slicksddm-customize --set "General/scale=$SDDM_SCALE"
    fi
fi

# --- apply now -------------------------------------------------------------------
if [ "$CHECK" = 0 ]; then
    if command -v kanshi >/dev/null 2>&1; then
        if pgrep -x kanshi >/dev/null 2>&1; then
            kanshictl reload >/dev/null 2>&1 || true
            say "kanshi reloaded"
        else
            ( setsid kanshi >/dev/null 2>&1 & ) || true
            say "kanshi started"
        fi
    fi
    echo
    echo "done. Verify:  wlr-randr | grep -A1 '$OUTPUT \"'"
fi

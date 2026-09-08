#!/bin/bash
# Read-only dependency check for keyboard-layout-indicator.
# Makes NO changes. Exits non-zero if a required dependency is missing.
#
#   ./check-dependencies.sh
set -u

ok=0; miss=0
yes() { printf '  [ ok ] %s\n' "$*"; }
no()  { printf '  [MISS] %s\n' "$*"; miss=$((miss+1)); }
inf() { printf '  [info] %s\n' "$*"; }

echo "Packages (dpkg):"
for p in python3-gi gir1.2-ayatanaappindicator3-0.1; do
    if dpkg -l "$p" 2>/dev/null | grep -q '^ii'; then
        yes "$p ($(dpkg-query -W -f='${Version}' "$p" 2>/dev/null))"
    else
        no "$p not installed  ->  sudo apt install $p"
    fi
done

echo "Build deps for xkb-monitor (only needed to (re)build it):"
for p in build-essential libwayland-dev libwayland-bin libxkbcommon-dev libxkbregistry-dev wayland-protocols; do
    if dpkg -l "$p" 2>/dev/null | grep -q '^ii'; then
        yes "$p"
    else
        inf "$p absent (fine if xkb-monitor is already built and installed)"
    fi
done

echo "xkb-monitor:"
if [ -x /usr/local/bin/xkb-monitor ]; then
    yes "/usr/local/bin/xkb-monitor present"
elif command -v xkb-monitor >/dev/null 2>&1; then
    inf "xkb-monitor found at $(command -v xkb-monitor), but the indicator calls /usr/local/bin/xkb-monitor literally"
    no "/usr/local/bin/xkb-monitor missing"
else
    no "/usr/local/bin/xkb-monitor missing  ->  see docs/INSTALL.md section 2"
fi

echo "System Python can load GI + Ayatana:"
if /usr/bin/python3 - <<'PY' 2>/dev/null
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("AyatanaAppIndicator3", "0.1")
from gi.repository import Gtk, GLib
from gi.repository import AyatanaAppIndicator3
PY
then
    yes "/usr/bin/python3 imports Gtk 3.0 + AyatanaAppIndicator3 0.1"
else
    no "/usr/bin/python3 cannot import the required typelibs (Conda Python? missing packages?)"
fi

echo "Panel AppIndicator host:"
inf "cannot be checked reliably from a script - if no badge appears after"
inf "install, add the 'Status Notifier' applet to the Budgie panel."

echo
if [ "$miss" -eq 0 ]; then
    echo "All required dependencies present."
    exit 0
else
    echo "$miss required dependency/dependencies missing (see [MISS] above)."
    exit 1
fi

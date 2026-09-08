#!/bin/sh
# Installed as /usr/bin/nemo (the package binary is diverted to /usr/bin/nemo.real).
#
# Preloads the GTK3 cursor-name shim so Nemo shows a horizontal resize cursor
# over GtkTreeView column boundaries on the native-Wayland session, then restores
# LD_PRELOAD (via the shim's constructor) so children Nemo spawns don't inherit
# it. Nemo itself stays on the Wayland GDK backend - GDK_BACKEND is not set.

export NEMO_CURSOR_FIX_ORIG_LD_PRELOAD="${LD_PRELOAD-}"

if [ -n "${LD_PRELOAD-}" ]; then
    export LD_PRELOAD="/usr/local/lib/libnemo-gtk3-cursor-fix.so:$LD_PRELOAD"
else
    export LD_PRELOAD="/usr/local/lib/libnemo-gtk3-cursor-fix.so"
fi

exec /usr/bin/nemo.real "$@"

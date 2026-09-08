# budgie-2604-setup

Fixes and tweaks for a fresh **Ubuntu Budgie 26.04** install (Wayland session,
Budgie / Magpie compositor, SDDM).

## Contents

| Directory | What it does |
|-----------|--------------|
| [`gufw-wayland-fix/`](gufw-wayland-fix/) | Makes **Firewall Configuration** (gufw) launch again on Wayland, without a permanent `xhost` grant in autostart. |

Each subdirectory is self-contained and has its own `README.md`, `install.sh`
and `uninstall.sh`.

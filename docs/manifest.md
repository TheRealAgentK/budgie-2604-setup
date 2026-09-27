# Manifest — live-system path ↔ repository path

Machine: TUXEDO InfinityBook Pro Gen7 MK1, Ubuntu Budgie 26.04 LTS, Wayland /
labwc, SDDM, NVIDIA+Intel hybrid (`mate-optimus`), internal output `eDP-1`.

All repository content is a **capture** of an already-working system. Installing
from this repo is a documented, manual, opt-in step. Verified read-only on
2026-09-08.

| Live-system source | Repository path | Type | State |
|---|---|---|---|
| `/usr/local/bin/nvidia-detector` | `nvidia-detector-shim/nvidia-detector` | exec shell script (`root:root 0755`) | **current** — byte-identical, SHA-256 `1e542017…e106` |
| `/etc/polkit-1/rules.d/10-enable-hibernate.rules` | `hibernate-polkit/10-enable-hibernate.rules` | PolicyKit JS rule (`root:root 0644`) | **current** (content from handoff; live file root-only, not byte-verified this session; `CanHibernate` → `yes`) |
| `/etc/sysctl.d/60-inotify.conf` | `inotify-watches/60-inotify.conf` | sysctl drop-in (`root:root 0644`) | **current** — byte-identical; running value `1000000` |
| `~/.config/autostart/Nextcloud.desktop` | `nextcloud-xcb-wayland/reference/Nextcloud.desktop` | XDG autostart entry (`kai:kai 0664`) | **current** — verbatim reference copy |
| Nextcloud XCB workaround (inline `env` in the `Exec=` above) | `nextcloud-xcb-wayland/scripts/nextcloud-xcb` | exec shell wrapper | repo representation only — **not installed** on the live machine |
| labwc autostart (`~/.config/budgie-desktop/labwc/autostart`) + `~/.config/kanshi/config` | `display-scaling/` | config + scripts | **current** — see that component |
| labwc autostart (`~/.config/budgie-desktop/labwc/autostart`) — `resume-display-on` block + `~/.local/bin/resume-display-on-listener` | `resume-display-on/` | managed autostart block + respawn-loop script | **current** — installed 2026-09-13; respawn loop added 2026-09-27 |
| labwc autostart — `swayidle-lock-guard` block + `~/.local/bin/swayidle-lock-guard` | `swayidle-lock-guard/` | managed autostart block + journal-watching script | **current** — installed 2026-09-27; recovery path dry-run tested, not yet seen live |
| slickSDDM `General/scale` | `display-scaling/` (documented) + `docs/sddm-scaling.md` | tool-managed setting | **current value `1.25`** |

## Not captured — superseded / out of scope

| Item from the TUXEDO handoff | Why it is not in the repo as an active fix |
|---|---|
| `~/.local/bin/fix-budgie-scale` (`wlr-randr --output eDP-1 --scale 1.2`) | **Does not exist on the machine.** Fractional scaling is now handled by `display-scaling/` (kanshi holds `eDP-1` at `2304x1440@90`, **scale 1.0**). Recorded as a removed experiment in the top-level README. |
| labwc `swayidle … after-resume/unlock fix-budgie-scale` hook | **Not present.** The only `swayidle` running is Budgie's stock screen-lock instance. |
| "fractional desktop scale 1.2" | Live scale is **1.0**. |
| SDDM `General/scale=1.5` | Live value is **`1.25`** (see `docs/sddm-scaling.md`). |
| `/swapfile`, resume offset, 8 GiB swap partition | Context only — see `hibernate-polkit/`. Repo ships **no** swap/resume tooling; `/swapfile` must never be recreated/resized/moved. |
| Legacy `com.ubuntu.enable-hibernate.pkla` | Removed on the live system; **must not be recreated.** |
| APT/Snap/Flatpak/cache/log/Docker/Conda cleanup, power/battery experiments, firmware audit, disk-usage analysis, `/opt` inventory | Explicitly out of scope of the capture. |

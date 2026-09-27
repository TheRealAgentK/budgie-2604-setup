# budgie-2604-setup

Fixes and tweaks for a fresh **Ubuntu Budgie 26.04** install on a
**TUXEDO InfinityBook Pro Gen7 MK1**.

```
Desktop:     Budgie          Session:  Wayland      Compositor: labwc
Display mgr: SDDM            Display:  eDP-1  (2880x1800 native panel)
Graphics:    NVIDIA RTX 3050 Ti + Intel Iris Xe hybrid (mate-optimus)
Nemo:        6.4.5           Cursor theme: Breeze_Light
```

## Components

Each directory is self-contained: its own `README.md`, docs, and conservative
scripts. Fixes that this repo actively manages ship an idempotent `install.sh`
(`--check` to report only); pure captures of already-working system state ship a
read-only `verify.sh` and document install steps without running them. See
[`docs/manifest.md`](docs/manifest.md) for the full live-path ↔ repo-path map.

| Directory | What it does |
|---|---|
| [`display-scaling/`](display-scaling/) | `eDP-1` held at `2304x1440@90Hz` scale `1.0` via **kanshi**; SDDM login screen kept at native `2880x1800` with theme UI scale `1.25`. |
| [`nemo-wayland-cursor-fix/`](nemo-wayland-cursor-fix/) | Restores the horizontal column-resize cursor in **Nemo** on native Wayland with an `LD_PRELOAD` shim — without forcing Nemo onto XWayland. |
| [`gufw-wayland-fix/`](gufw-wayland-fix/) | Makes **Firewall Configuration** (gufw) launch on Wayland by granting local-root X access only for the lifetime of its window — no permanent `xhost` grant. |
| [`keyboard-layout-indicator/`](keyboard-layout-indicator/) | Panel **EN / DE keyboard-layout badge** (Python + Ayatana AppIndicator) driven by `xkb-monitor`. Observation only. Faithful capture of an already-installed setup. |
| [`nvidia-detector-shim/`](nvidia-detector-shim/) | Minimal `/usr/local/bin/nvidia-detector` replacement so **`mate-optimus`** can still detect the NVIDIA GPU on 26.04. Capture (SHA-256 verified). |
| [`hibernate-polkit/`](hibernate-polkit/) | Native PolicyKit JS rule restoring **Hibernate** in the Budgie UI (legacy `.pkla` no longer honoured). Capture. Swap/resume config is context only — never touch `/swapfile`. |
| [`inotify-watches/`](inotify-watches/) | `fs.inotify.max_user_watches = 1000000` sysctl drop-in. Capture. |
| [`nextcloud-xcb-wayland/`](nextcloud-xcb-wayland/) | Runs the **Nextcloud** AppImage (xcb-only Qt) under the Wayland session by forcing `QT_QPA_PLATFORM=xcb` for that app alone. Wrapper + reference autostart entry. |
| [`resume-display-on/`](resume-display-on/) | Turns the panel back on after **suspend/resume**. Budgie's idle `swayidle` switches outputs off at 5 min and only re-enables them on idle activity, so waking from the battery idle-suspend left a black screen. Adds an `after-resume` listener, respawned after `budgie-daemon`'s `killall swayidle`, via a marked labwc autostart block. |
| [`swayidle-lock-guard/`](swayidle-lock-guard/) | Restores the **lock screen and fast suspend** when Budgie's `swayidle` stops handling suspend. Each suspend then waited 30 s for its stale inhibitor and woke unlocked. It watches logind's journal for that inhibitor timeout, locks the screen, and restarts that `swayidle` with its own arguments. Marked labwc autostart block. |
| [`charge-limit-alert/`](charge-limit-alert/) | Warns to **unplug at 80 %**, because this board's EC ignores TCC's stationary charging profile and always charges to 100 %. `charge-guard` user service with desktop notifications and optional smart-plug cutoff hooks. |

They are independent; install any subset.

## Conventions

- **User files** are backed up to `<file>.bak-<timestamp>` before being changed.
- **Shared files** (e.g. the labwc `autostart`) are edited only inside a marked
  block:

  ```
  # >>> budgie-2604-setup:<component> >>>
  ...
  # <<< budgie-2604-setup:<component> <<<
  ```

  The rest of the file is never touched.
- **`sudo`** is used only when a change actually requires it; `--check` never
  escalates.
- Package-owned files are not edited in place — `dpkg-divert` and
  `slicksddm-customize` are used instead.

## Removed experiments — do NOT reintroduce

These were tried while debugging and deliberately abandoned. Do not let any
script or future change recreate them.

**Nemo forced onto XWayland** — `GDK_BACKEND=x11` for Nemo. Restored the resize
cursor but broke drag-and-drop from Nemo into native-Wayland Brave. Includes:

- `~/.local/share/applications/nemo.desktop`, `nemo.desktop.budgie`,
  `nemo.desktop.backup`
- `~/.local/share/dbus-1/services/org.Nemo.service`,
  `~/.local/share/dbus-1/services/org.freedesktop.FileManager1.service`

**Experimental cursor themes** — `Breeze_Light-GTK3Fix`, `Breeze_GTK_Test`
(under `~/.local/share/icons/` and `~/.icons/`). Aliasing/removing cursor files
did not help; the failure follows the cursor *name*. Cursor theme stays
`Breeze_Light`.

**SDDM forced modeline** — `/etc/sddm.conf.d/60-display-resolution.conf` and
`/usr/local/libexec/sddm-display-setup`, forcing SDDM/Xorg to `2304x1440@90`.
Xorg did not reliably expose that custom mode. Replaced by native `2880x1800` +
theme scale `1.25`.

**Fractional-scaling resume hacks** — `~/.local/bin/fix-budgie-scale` and any
`wlr-randr --output eDP-1 --scale 1.2` workaround. Replaced by
`2304x1440 @ scale 1.0` reasserted by kanshi.

## License

[MIT](LICENSE).

# System changes — historical record only

> **These commands were run manually by the user before this capture, on
> 2026-08-18.** They are recorded here for reproducibility on another machine.
> They must **not** be executed as part of creating or maintaining this
> repository. Nothing in this directory re-applies them.

The machine is Ubuntu Budgie 26.04, Wayland / labwc.

## 1. Build dependencies for `xkb-monitor`

Installed:

```sh
sudo apt install \
    libwayland-dev \
    libxkbcommon-dev \
    wayland-protocols \
    libwayland-bin \
    libxkbregistry-dev
```

`git`, `build-essential` and `curl` were already present.

### Build problem that had to be solved

The first build failed because Ubuntu 26.04 splits the XKB **registry**
development headers into their own package:

```
Package 'xkbregistry' not found
fatal error: xkbcommon/xkbregistry.h: No such file or directory
```

Installing **`libxkbregistry-dev`** fixed it. (On this machine it is
`libxkbregistry-dev` 1.13.1-1, providing `xkbcommon/xkbregistry.h` and the
`xkbregistry` pkg-config module.)

### Versions observed on this machine (2026-09-08)

| Package | Version |
|---|---|
| `libwayland-dev` | 1.24.0-2 |
| `libwayland-bin` | 1.24.0-2 |
| `libxkbcommon-dev` | 1.13.1-1 |
| `libxkbregistry-dev` | 1.13.1-1 |
| `wayland-protocols` | 1.47-1 |

## 2. `xkb-monitor`

Cloned manually:

```sh
git clone https://github.com/drougas/xkb-monitor.git /tmp/xkb-monitor
# built there (see that project's README), then:
sudo install -m 0755 /tmp/xkb-monitor/xkb-monitor /usr/local/bin/xkb-monitor
```

Current state on this machine:

```
/usr/local/bin/xkb-monitor   root:root   -rwxr-xr-x   31408 bytes   2026-08-18 20:57
ELF 64-bit LSB pie executable, x86-64, dynamically linked, stripped
```

`/tmp/xkb-monitor` no longer exists (cleared on reboot — `/tmp` is not
persistent). Only the installed binary remains. If the source is needed again,
re-clone from the URL above.

`xkb-monitor -n` was tested and correctly streams layout names, e.g.:

```
us
de
us
```

## 3. Ayatana / Python support

Installed:

```sh
sudo apt install python3-gi gir1.2-ayatanaappindicator3-0.1
```

Versions on this machine: `python3-gi` 3.56.2-1,
`gir1.2-ayatanaappindicator3-0.1` 0.5.94-1build1.

The indicator must run under **`/usr/bin/python3`**, because the GI and Ayatana
typelibs are installed for the system interpreter. The user's shells often have
the Conda `base` environment active, whose Python cannot see these packages —
hence the explicit `#!/usr/bin/python3` shebang and the explicit interpreter
path in the autostart entry.

## 4. Files created (user-level)

| Path | Mode | Created | Purpose |
|---|---|---|---|
| `~/.local/bin/keyboard-layout-indicator` | `0775` | 2026-08-18 21:02 | the indicator program |
| `~/.local/share/keyboard-layout-indicator/icons/kbd-en.svg` | `0664` | 2026-08-18 21:00 | EN badge |
| `~/.local/share/keyboard-layout-indicator/icons/kbd-de.svg` | `0664` | 2026-08-18 21:02 | DE badge |
| `~/.config/autostart/keyboard-layout-indicator.desktop` | `0664` | 2026-08-18 21:04 | start on login |

Repository copies: `src/keyboard-layout-indicator`, `icons/kbd-en.svg`,
`icons/kbd-de.svg`, `packaging/keyboard-layout-indicator.desktop.example`.

## 5. Autostart — confirmed present

At the time of this capture (2026-09-08) the autostart entry **does exist** on
this machine:

`~/.config/autostart/keyboard-layout-indicator.desktop` (219 bytes, 2026-08-18
21:04):

```ini
[Desktop Entry]
Type=Application
Name=Keyboard Layout Indicator
Comment=Show current keyboard layout in the Budgie panel
Exec=/home/<user>/.local/bin/keyboard-layout-indicator
Terminal=false
X-GNOME-Autostart-enabled=true
```

(The handoff that prompted this capture listed autostart as "NOT CONFIRMED";
a read-only check resolved it to *present*, with exactly the contents above.)

## 6. What was NOT changed

- Keyboard **layout switching** — still handled by Budgie / labwc / XKB via
  GSettings input sources.
- GSettings keys, including `switch-input-source` /
  `switch-input-source-backward` — unchanged.
- labwc configuration — unchanged.
- The Budgie panel configuration — unchanged (the indicator uses the existing
  AppIndicator host).
- No IBus / Fcitx5 / input-method framework was introduced.

# keyboard-layout-indicator

A small **EN / DE keyboard-layout indicator** for the Ubuntu Budgie 26.04
top-panel status area.

> **Status of this directory:** it is a *faithful capture* of a solution that is
> already installed and working on this machine (since 2026-08-18). The files
> here are copies of the live ones. Installing from this directory is an
> optional, documented, manual step — see [`docs/INSTALL.md`](docs/INSTALL.md).
> Nothing in here has been run against the live desktop.

## What it does

Budgie 26.04 (Wayland / labwc) no longer ships the old X11-era "Keyboard Layout"
panel applet. Layout switching itself already works (via GSettings input
sources and the labwc/XKB stack), but there was **no visible indication** of
which layout is active.

This project adds only the missing *indicator*:

- [`xkb-monitor`](https://github.com/drougas/xkb-monitor) (external dependency)
  watches the active XKB layout and prints its name (`us`, `de`, …) on stdout.
- `src/keyboard-layout-indicator` (Python 3 + Ayatana AppIndicator) reads that
  stream and shows a small `EN` or `DE` badge in the existing Budgie
  AppIndicator / status area.

It is **observation only**. It does not switch layouts, does not touch
GSettings, labwc, the Budgie panel, or the keyboard shortcuts, and is **not** an
input-method framework (no IBus, no Fcitx5). See
[`docs/TECHNICAL-NOTES.md`](docs/TECHNICAL-NOTES.md) for why that approach was
chosen.

## Target environment

| | |
|---|---|
| Distro | Ubuntu Budgie 26.04 |
| Session | Wayland, labwc compositor |
| Panel | Budgie panel with an **AppIndicator / Status Notifier host** applet |
| Python | system **`/usr/bin/python3`** (not Conda — Ubuntu's GI / Ayatana typelibs are installed for the system interpreter) |
| Layout switching | unchanged; still owned by Budgie / labwc / XKB via GSettings input sources |

Observed input-source shortcuts on this machine (for reference — **not managed
by this project**):

```
switch-input-source           ['<Alt>Shift_L', '<Super>space', 'XF86Keyboard']
switch-input-source-backward  ['<Super><Shift>space', '<Shift>XF86Keyboard']
```

## Contents

```
keyboard-layout-indicator/
├── README.md                 – this file
├── src/
│   └── keyboard-layout-indicator      – the indicator program (Python 3)
├── icons/
│   ├── kbd-en.svg                     – "EN" badge
│   └── kbd-de.svg                     – "DE" badge
├── docs/
│   ├── INSTALL.md                     – manual setup on another machine
│   ├── TECHNICAL-NOTES.md             – architecture + design rationale
│   └── SYSTEM-CHANGES.md              – historical record of changes already made
├── packaging/
│   └── keyboard-layout-indicator.desktop.example  – autostart template
└── scripts/
    ├── check-dependencies.sh          – read-only dependency check
    ├── install.sh                     – optional installer (supports --dry-run)
    └── uninstall.sh                   – optional uninstaller (supports --dry-run)
```

## Runtime dependencies

- An **AppIndicator host** in the Budgie panel (Status Notifier / AppIndicator
  applet). Without it the process runs but nothing appears.
- **`/usr/local/bin/xkb-monitor`** — this implementation calls that path
  literally (see `monitor_layout()` in `src/keyboard-layout-indicator`).
  `xkb-monitor` is *not* vendored here; obtain it per
  [`docs/INSTALL.md`](docs/INSTALL.md).
- System Python packages: `python3-gi`,
  `gir1.2-ayatanaappindicator3-0.1`.

## Supported layout mappings

From the `LAYOUTS` dict in `src/keyboard-layout-indicator`:

| XKB layout name | Icon | Description |
|---|---|---|
| `us` | `kbd-en` | English |
| `gb` | `kbd-en` | English |
| `au` | `kbd-en` | English |
| `nz` | `kbd-en` | English |
| `de` | `kbd-de` | German |

Any **unmapped** layout falls back to the `kbd-en` icon with the layout name
upper-cased as its description (e.g. `fr` → shows the EN badge, tooltip `FR`).

### Adding a layout

1. Add an SVG named `kbd-<something>.svg` to `icons/` (and, once installed, to
   `~/.local/share/keyboard-layout-indicator/icons/`).
2. Add an entry to `LAYOUTS`, e.g.:

   ```python
   "fr": ("kbd-fr", "French"),
   ```

The icon name is the SVG basename without `.svg`; the indicator loads icons
from its `set_icon_theme_path(ICON_DIR)` directory.

## Manual test

With an AppIndicator host running in the panel and `xkb-monitor` on `PATH`:

```sh
# see raw layout events
/usr/local/bin/xkb-monitor -n
# then switch layout with your shortcut; expect lines like:  us / de / us

# run the indicator in the foreground (system Python!)
/usr/bin/python3 ./src/keyboard-layout-indicator
```

A badge should appear in the panel and flip between `EN` and `DE` as you switch.
Use the indicator's **Quit** menu item to stop it.

> Do not run this repository copy as a replacement for the already-installed,
> already-working `~/.local/bin/keyboard-layout-indicator` on this machine.

## Possible improvements (not implemented here)

See [`TODO.md`](TODO.md). This directory intentionally captures the
known-working implementation as-is before any redesign.

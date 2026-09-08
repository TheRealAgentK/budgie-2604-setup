# Nextcloud AppImage under Budgie Wayland

## Problem

The Budgie Wayland session launcher `/usr/bin/startbudgielabwc` exports
`QT_QPA_PLATFORM=wayland` for the whole session (only if it is unset —
verified: lines 75-77, `if [ -z "${QT_QPA_PLATFORM}" ]; then …`).

The Nextcloud AppImage in `/opt` bundles **only** the Qt `xcb` platform plugin,
so it fails to start under the session default:

```
qt.qpa.plugin: Could not find the Qt platform plugin "wayland" in ""
Available platform plugins are: xcb.
```

It works when *that one application* is forced to XCB / XWayland:

```sh
QT_QPA_PLATFORM=xcb /opt/Nextcloud-34.0.1-x86_64.AppImage
```

## Constraints

- **Do not edit `/usr/bin/startbudgielabwc`.** The session forcing Qt to Wayland
  is intentional; the workaround stays application-specific.
- Do not change the global Qt environment.

## Live state (verified 2026-09-08 — do not modify)

| | |
|---|---|
| AppImage | `/opt/Nextcloud-34.0.1-x86_64.AppImage` (`root:root`, `0755`, ~64 MiB) |
| Autostart | `~/.config/autostart/Nextcloud.desktop` (`kai:kai`, `0664`) |
| Autostart `Exec=` | `env QT_QPA_PLATFORM=xcb "/opt/Nextcloud-34.0.1-x86_64.AppImage" --background` |
| `startbudgielabwc` | sets `QT_QPA_PLATFORM=wayland` when unset (lines 75-77) |

The current implementation embeds the `env` override directly in the `.desktop`
`Exec=` line. A verbatim copy of that file is kept for reference at
[`reference/Nextcloud.desktop`](reference/Nextcloud.desktop).

## Repo wrapper

[`scripts/nextcloud-xcb`](scripts/nextcloud-xcb) is a repository representation
of the same workaround:

```sh
#!/bin/sh
exec env QT_QPA_PLATFORM=xcb /opt/Nextcloud-34.0.1-x86_64.AppImage "$@"
```

> This wrapper is **not** installed on the live machine (the live setup uses the
> inline `Exec=` form above). It is here as the portable representation of the
> fix.

An autostart entry could call the wrapper instead of embedding the override:

```
Exec=/usr/local/bin/nextcloud-xcb --background
```

Update the AppImage path/version in the wrapper when Nextcloud is upgraded (or
generalise it to glob `/opt/Nextcloud-*-x86_64.AppImage` — left literal here to
match the live state).

## Installing on another machine (documentation only — not run here)

```sh
sudo install -m 0755 scripts/nextcloud-xcb /usr/local/bin/nextcloud-xcb
# then either keep the inline Exec= form, or point the autostart entry at the wrapper:
#   Exec=/usr/local/bin/nextcloud-xcb --background
```

## Verify (read-only)

```sh
./verify.sh
```

Prints the live autostart `Exec=` line, checks the AppImage exists, and shows
the `QT_QPA_PLATFORM` handling in `startbudgielabwc`.

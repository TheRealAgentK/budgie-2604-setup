# Nemo native-Wayland resize-cursor fix

## Symptom

On the native-Wayland Budgie/labwc session, Nemo 6.4.5 can resize
`GtkTreeView` (detail view) columns, but **no horizontal resize cursor** appears
when the pointer is over a column boundary.

## What the problem actually is

Reduced to a minimal GTK3 program calling `gdk_cursor_new_from_name()`:

| cursor name | Wayland GDK backend | X11 GDK backend |
|---|---|---|
| `col-resize` | **not shown** | shown |
| `ew-resize` | **not shown** | shown |
| `h_double_arrow` | shown | shown |
| `sb_h_double_arrow` | shown | shown |
| `pointer`, `crosshair` | shown | shown |

Tested with `Breeze_Light` and `Adwaita`, and with cursor themes where
`col-resize`, `ew-resize` and `h_double_arrow` all resolve to identical cursor
artwork. `col-resize` / `ew-resize` still failed while `h_double_arrow` worked —
so **the failure follows the cursor name, not the artwork**. This looks like a
GTK3-Wayland-backend issue, but it has only been reproduced under Budgie/labwc
and has not been cross-tested on another compositor (keep that caveat in any
upstream report).

## Why not just force Nemo onto X11

`GDK_BACKEND=x11` does restore the cursor — but then drag-and-drop from Nemo
(XWayland) into native-Wayland Brave stops working. That workaround, and the
desktop-file / D-Bus-service overrides that carried it, were **removed**. Nemo
stays native Wayland. See [main README, "Removed experiments"](../README.md).

## The fix

A small `LD_PRELOAD` shim (`src/nemo-gtk3-cursor-fix.c`) intercepts
`gdk_cursor_new_from_name()` and rewrites the two failing names:

```
col-resize  -> h_double_arrow
ew-resize   -> h_double_arrow
```

Its constructor then restores `LD_PRELOAD` to its previous value, so processes
Nemo launches do not inherit the shim. It does **not** touch `GDK_BACKEND`.

### Delivery

| Piece | Path | Why |
|---|---|---|
| shim | `/usr/local/lib/libnemo-gtk3-cursor-fix.so` | built from the C source by `install.sh` |
| wrapper | `/usr/bin/nemo` | sets `LD_PRELOAD` then `exec`s the real binary |
| divert | `/usr/bin/nemo` → `/usr/bin/nemo.real` | the Budgie Applications Menu and Super-key search launch `/usr/bin/nemo` directly, so a desktop-file override is not enough; `dpkg-divert` protects the package binary from being overwritten on upgrade |

## Install

```sh
./install.sh            # build + install (idempotent; safe to re-run)
./install.sh --check     # report state only, change nothing
```

Needs `gcc` (`build-essential`) and `sudo`. It refuses to run if it finds a
half-configured state (e.g. `/usr/bin/nemo.real` present with no divert
registered).

## Uninstall

```sh
./uninstall.sh
```

Quits Nemo, removes the wrapper, `dpkg-divert --remove --rename` (restoring the
packaged `/usr/bin/nemo`), and deletes the shim. Verifies the divert state
before doing anything destructive.

## Verify

```sh
dpkg-divert --list | grep '/usr/bin/nemo'          # local diversion ... to /usr/bin/nemo.real
ls -l /usr/bin/nemo /usr/bin/nemo.real /usr/local/lib/libnemo-gtk3-cursor-fix.so
gsettings get org.gnome.desktop.interface cursor-theme   # 'Breeze_Light'
```

Functional:

- resize a Nemo detail-view column → horizontal resize cursor appears
- drag a file from Nemo into native-Wayland Brave → works
- launch Files from the Applications Menu **and** from Super-key search → cursor
  fix active in both

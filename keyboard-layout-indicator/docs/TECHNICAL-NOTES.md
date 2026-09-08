# Technical notes

## Architecture

```
  keyboard shortcut  (<Alt>Shift_L, <Super>space, XF86Keyboard, …)
          |
          v
  Budgie / labwc / XKB          <- owns layout switching (GSettings input sources)
          |
          |  active-layout change
          v
  xkb-monitor -n                <- observes XKB state, one layout name per line
          |
          |  stdout:  "us"  /  "de"  /  "us"  …
          v
  keyboard-layout-indicator     <- Python 3, /usr/bin/python3
    - background thread reads xkb-monitor stdout
    - GLib.idle_add(update_layout, line) marshals to the GTK main loop
    - maps layout name -> (icon, description) via LAYOUTS, else falls back
          |
          v
  Ayatana AppIndicator          <- indicator.set_icon_full(icon, description)
          |
          v
  Budgie panel                  <- existing AppIndicator / Status Notifier host
```

### Process model

- One process. `Gtk.main()` on the main thread; a single `daemon=True` thread
  runs `monitor_layout()`.
- `monitor_layout()` `Popen`s `/usr/local/bin/xkb-monitor -n` and iterates
  `process.stdout` line by line (`bufsize=1`, `text=True`).
- Each line is handed to the GTK loop with `GLib.idle_add(update_layout, line)`
  — GTK/AppIndicator calls must happen on the main loop, not the reader thread.
- `update_layout()` returns `False` so the idle source fires once.
- If `xkb-monitor` exits, the `while True` loop waits ~1 s
  (`GLib.usleep(1_000_000)`) and respawns it.

### Icon handling

- Icons are looked up by name from a directory set with
  `indicator.set_icon_theme_path(ICON_DIR)`, where
  `ICON_DIR = ~/.local/share/keyboard-layout-indicator/icons`.
- Names in code (`kbd-en`, `kbd-de`) are SVG basenames without extension.
- `LAYOUTS` maps XKB layout name → `(icon_name, human_description)`.
- Unmapped layout → `("kbd-en", layout.upper())`: EN badge, layout code as
  tooltip. (A known rough edge — see "Improvements".)

### Why `/usr/bin/python3` explicitly

Ubuntu's `python3-gi` and `gir1.2-ayatanaappindicator3-0.1` install typelibs
and the `gi` module for the **system** interpreter. The user frequently has the
Conda `base` environment active in shells; its Python has no access to those.
The script's shebang is `#!/usr/bin/python3` and the autostart `Exec=` points at
the script (which therefore also uses the system interpreter). Running it as
`python3 keyboard-layout-indicator` from a Conda shell would fail at
`gi.require_version(...)`.

## Design rationale — why not replace the input stack

The visible problem ("no layout indicator on Budgie 26.04 / Wayland") could be
"solved" by switching the whole input pipeline to **Fcitx5** or **IBus**, both
of which have their own tray indicators. That was deliberately **not** done:

- **Layout switching already works.** labwc + XKB + GSettings input sources
  handle it, including the user's existing shortcuts. Replacing that stack risks
  regressions in switching behaviour to fix a *display* gap.
- **Smaller blast radius.** This solution adds one observer process and a panel
  icon. It changes no GSettings, no labwc config, no panel config, no
  shortcuts. Removing it leaves the system exactly as before.
- **No new input-method daemon** running for every GUI app, no per-app
  integration quirks (Fcitx5/IBus module env vars, XWayland edge cases, etc.).
- **Compositor-agnostic-ish.** `xkb-monitor` reads XKB state; the indicator is a
  standard AppIndicator client. Nothing depends on Budgie internals beyond the
  panel hosting an AppIndicator.

Trade-offs accepted:

- Depends on `xkb-monitor` as an out-of-repo binary at a fixed path.
- Layout → icon mapping is hard-coded in the script.
- The child `xkb-monitor` process is not shut down gracefully on quit (the
  daemon thread just dies with the process).

These are recorded in [`../TODO.md`](../TODO.md) as future work, not fixed here —
this directory captures the known-working implementation verbatim.

## Failure modes

| Condition | Behaviour |
|---|---|
| No AppIndicator host in panel | Process runs; no icon visible |
| `xkb-monitor` missing at the hard-coded path | `monitor_layout()` catches the exception, prints `xkb-monitor error: …`, retries every ~1 s forever |
| `xkb-monitor` exits / crashes | Respawned after ~1 s |
| Unknown layout name | EN icon + upper-cased code as description |
| Blank line from `xkb-monitor` | Ignored (`if not layout: return False`) |

# TODO / possible improvements

Not implemented — this directory captures the known-working implementation
as-is. Listed here so the ideas are not lost.

- **Configurable `xkb-monitor` path** — currently hard-coded as
  `/usr/local/bin/xkb-monitor` in `monitor_layout()`. Read from an env var or a
  small config file, fall back to `PATH`.
- **Layout → icon mapping in a config file** instead of the `LAYOUTS` dict in
  the script (e.g. `~/.config/keyboard-layout-indicator/layouts.ini`).
- **Dynamic icon for unmapped layouts** — render the layout code onto the badge
  at runtime instead of falling back to the EN icon.
- **Graceful child shutdown** — terminate the `xkb-monitor` child on Quit /
  `SIGTERM` rather than letting the daemon thread die with the process.
- **Cleaner logging** — capture `xkb-monitor` stderr, use `logging` with a
  level, don't just `print()`.
- **Consistent XDG paths** — `ICON_DIR` uses `~/.local/share/...` directly;
  honour `$XDG_DATA_HOME`.
- **More language icons** — ship a small set (fr, es, it, …) and matching
  `LAYOUTS` entries.
- **Tests** — pure unit tests for the layout-name → `(icon, description)`
  mapping, including the fallback and blank-line cases.
- **Packaging** — a `.deb`, or a distro-agnostic installer that also handles the
  `xkb-monitor` dependency.
- **System-independent install** — the current `scripts/install.sh` only does
  the user-level files; packages and `xkb-monitor` are still manual.

# Installing on another Ubuntu Budgie 26.04 machine

> Every command below is for **a human to run**. Nothing in this repository
> executes them for you. On the machine where this was first built, all of this
> is already done — do not re-run it there.

The install has four parts:

1. build-time and run-time packages
2. `xkb-monitor` (external — build + install to `/usr/local/bin`)
3. the indicator program and its icons (into `~/.local`)
4. autostart (optional)

You can also use [`../scripts/install.sh`](../scripts/install.sh) for parts 3–4;
read it first, and note it does **not** do parts 1–2.

---

## 0. Prerequisites

- Ubuntu Budgie 26.04, Wayland / labwc session.
- A **Status Notifier / AppIndicator host** applet in the Budgie panel. Budgie
  normally provides this; if the badge never appears later, add the
  "Status Notifier" applet to the panel.
- Use the **system** Python. If you use Conda/mamba, deactivate it for these
  steps (`conda deactivate` until `which python3` is `/usr/bin/python3`), or
  just call `/usr/bin/python3` explicitly.

---

## 1. Packages

Runtime:

```sh
sudo apt install python3-gi gir1.2-ayatanaappindicator3-0.1
```

Build dependencies for `xkb-monitor`:

```sh
sudo apt install \
    build-essential git \
    libwayland-dev libwayland-bin \
    libxkbcommon-dev libxkbregistry-dev \
    wayland-protocols
```

> **`libxkbregistry-dev` is the one people miss.** Ubuntu 26.04 ships the XKB
> registry headers separately from `libxkbcommon-dev`. Without it the build
> fails with `fatal error: xkbcommon/xkbregistry.h: No such file or directory`
> / `Package 'xkbregistry' not found`. See
> [`SYSTEM-CHANGES.md`](SYSTEM-CHANGES.md).

---

## 2. `xkb-monitor` (external dependency)

This indicator implementation calls `/usr/local/bin/xkb-monitor` **by that
literal path**. Build and install it there:

```sh
git clone https://github.com/drougas/xkb-monitor.git
cd xkb-monitor
# follow that project's own build instructions (Meson/Make as documented there)
# then install the resulting binary:
sudo install -m 0755 ./xkb-monitor /usr/local/bin/xkb-monitor
cd ..
```

Verify:

```sh
/usr/local/bin/xkb-monitor -n
# switch keyboard layout with your shortcut; expect lines like:
#   us
#   de
```

If you install it somewhere else, change the path in
`monitor_layout()` inside the indicator script before installing part 3.

---

## 3. Indicator program + icons

From the repository root:

```sh
# program
install -D -m 0755 keyboard-layout-indicator/src/keyboard-layout-indicator \
    ~/.local/bin/keyboard-layout-indicator

# icons
install -D -m 0644 keyboard-layout-indicator/icons/kbd-en.svg \
    ~/.local/share/keyboard-layout-indicator/icons/kbd-en.svg
install -D -m 0644 keyboard-layout-indicator/icons/kbd-de.svg \
    ~/.local/share/keyboard-layout-indicator/icons/kbd-de.svg
```

Make sure `~/.local/bin` is on your `PATH` (Budgie/Ubuntu usually adds it via
`~/.profile` when the directory exists — you may need to log out/in once).

Test in the foreground:

```sh
/usr/bin/python3 ~/.local/bin/keyboard-layout-indicator
```

A small `EN`/`DE` badge should appear in the panel and follow layout changes.
Stop it from its **Quit** menu item.

---

## 4. Autostart (optional)

A user autostart entry needs the **absolute path** to the installed program, so
it can't be fully generic. Copy the template and fill in the path:

```sh
mkdir -p ~/.config/autostart
sed "s|@EXEC@|$HOME/.local/bin/keyboard-layout-indicator|" \
    keyboard-layout-indicator/packaging/keyboard-layout-indicator.desktop.example \
    > ~/.config/autostart/keyboard-layout-indicator.desktop
```

Resulting file (this is exactly what is on the original machine, with the real
home path substituted):

```ini
[Desktop Entry]
Type=Application
Name=Keyboard Layout Indicator
Comment=Show current keyboard layout in the Budgie panel
Exec=/home/<you>/.local/bin/keyboard-layout-indicator
Terminal=false
X-GNOME-Autostart-enabled=true
```

Log out and back in; the indicator should start automatically.

> The `Exec` line has no explicit `/usr/bin/python3` because the program's
> shebang is already `#!/usr/bin/python3`. If you keep your login shell in a
> Conda env and see import errors at login, change `Exec` to
> `Exec=/usr/bin/python3 /home/<you>/.local/bin/keyboard-layout-indicator`.

---

## Uninstall

Manually:

```sh
rm -f ~/.config/autostart/keyboard-layout-indicator.desktop
pkill -f "$HOME/.local/bin/keyboard-layout-indicator" 2>/dev/null || true
rm -f ~/.local/bin/keyboard-layout-indicator
rm -rf ~/.local/share/keyboard-layout-indicator
# xkb-monitor is a general-purpose tool; remove only if nothing else uses it:
# sudo rm -f /usr/local/bin/xkb-monitor
```

or use [`../scripts/uninstall.sh`](../scripts/uninstall.sh) (review it first;
it never touches `xkb-monitor` and never uses `sudo`).

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| No badge in the panel | No AppIndicator / Status Notifier host applet in the Budgie panel |
| `ValueError: Namespace ... AyatanaAppIndicator3 not available` | Running under Conda Python, or `gir1.2-ayatanaappindicator3-0.1` not installed |
| `FileNotFoundError: '/usr/local/bin/xkb-monitor'` | Part 2 not done, or installed to a different path |
| Badge appears but never changes | `xkb-monitor -n` not emitting events for your compositor; test it standalone |
| Badge always shows `EN` for a non-English layout | That layout isn't in `LAYOUTS` — add it (see main README) |

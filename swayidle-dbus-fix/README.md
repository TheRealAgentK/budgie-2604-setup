# swayidle-dbus-fix

Fixes the root cause behind **30-second suspends with no lock screen**. It runs
`swayidle` 1.9.0 with upstream commit
[`a959e59`](https://github.com/swaywm/swayidle/commit/a959e59c64b55dd17a974dda4c4b71dff520af3a)
("Drain the sd-bus queue in the check pass") applied, installed as
`~/.local/bin/swayidle`.

## Cause

Ubuntu 26.04 ships `swayidle 1.9.0-1`. Its D-Bus handler, `dbus_event()`,
calls `sd_bus_process()` **once** per "socket readable" wakeup. The follow-up
check pass (`mask == 0`) only flushes; it never processes.

sd-bus keeps its own queue of messages it has already read. A synchronous
`sd_bus_call_method()` puts every unrelated message that arrives while it waits
for its reply into that queue. On resume, `swayidle` makes exactly such a call:
`Inhibit`, to take its sleep inhibitor back. If logind sends another
`PrepareForSleep` during that call, the message gets queued and has already
been read from the socket. `poll()` therefore never wakes for it, and it stays
in the queue.

After that, `swayidle` handles each sleep signal **one event late**:

- It is still holding its *delay* inhibitor when a suspend starts, so logind
  waits the full 30 s and logs
  `Delay lock is active (… PID N/swayidle) but inhibitor timeout is reached`.
- `before-sleep` (Budgie's `swaylock`) doesn't run before the suspend, so the
  laptop wakes unlocked.

It stays this way until that `swayidle` is restarted. Any `swayidle` with a
logind sleep handler is affected: Budgie's own instance and the
`resume-display-on` listener both got stuck.

Upstream hit the same queueing with `SetIdleHint` + `Session.Lock`
([swayidle#204](https://github.com/swaywm/swayidle/issues/204)). The fix,
dated 2026-08-27, drains the queue in the check pass. It came after the
v1.9.0 tag, so no release includes it yet.

## Evidence (this machine)

| Date | Stuck `swayidle` | Suspends affected |
|---|---|---|
| 2026-09-22 → 09-27 | Budgie's (PID 4740) | 8. It went stuck right after a lid close/open 7 ms apart. |
| 2026-10-01 00:31 | `resume-display-on` listener (PID 2283830) | 1 so far |

In both cases the stuck process held a sleep inhibitor long after every other
process had re-taken theirs on resume.

## Fix

`install.sh`:

1. downloads the `v1.9.0` tarball from GitHub and checks its SHA-256
   (`161f5827…af656`);
2. applies `patches/0001-drain-sd-bus-queue-in-check-pass.patch`, the upstream
   commit unmodified;
3. builds it with Ubuntu's feature set (`logind` via systemd; man pages and
   shell completions off) in
   `~/.cache/budgie-2604-setup/swayidle-1.9.0-patched/`;
4. installs the binary as `~/.local/bin/swayidle`;
5. restarts running `swayidle` processes that still use `/usr/bin/swayidle`.
   Budgie's gets the same arguments again. The `resume-display-on` listener is
   killed and its loop respawns it.

`~/.local/bin` comes before `/usr/bin` on the PATH of labwc, `budgie-daemon`
and the labwc autostart, so every `swayidle` the session starts uses this
binary. The `swayidle` package, `/usr/bin/swayidle` and `budgie-daemon` are not
touched.

Build dependencies, already present on this machine: `meson`, `ninja-build`,
`build-essential`, `pkg-config`, `libwayland-dev`, `wayland-protocols`,
`libsystemd-dev`.

## When Ubuntu updates swayidle

`install.sh --check` reports the packaged version. Once it isn't `1.9.0-1`, see
whether the new package includes `a959e59`. If it does, run `./uninstall.sh`;
otherwise `~/.local/bin/swayidle` would keep shadowing the newer package.

## Install / remove

```
./install.sh --check      # report only
./install.sh              # build (once), install, restart running swayidles
./uninstall.sh            # remove the binary, restart swayidles onto /usr/bin
./uninstall.sh --purge    # ...and delete the build cache
```

`uninstall.sh` removes `~/.local/bin/swayidle` only if it matches the cached
patched build.

## Verify

```
for p in $(pgrep -x swayidle); do echo "$p $(readlink /proc/$p/exe)"; done   # all ~/.local/bin/swayidle
journalctl -b | grep 'inhibitor timeout'                                      # should stay empty
```

`swayidle-lock-guard` stays installed as a safety net. If this fix is somehow
not enough, its log (`journalctl -t swayidle-lock-guard`) shows every recovery.

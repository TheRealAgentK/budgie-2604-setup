# swayidle-lock-guard

Recovers a `swayidle` that has stopped handling suspend. When that happens,
every suspend **takes 30 s** and the laptop **wakes without a lock screen**.

**The root cause is fixed by [`swayidle-dbus-fix/`](../swayidle-dbus-fix/).**
This component is the safety net in case that fix isn't enough, or after a
package update replaces it.

## Cause

Budgie's idle handling is a `swayidle -w … before-sleep swaylock -Fklf …`
instance started by `budgie-daemon`. It holds a logind *delay* sleep inhibitor.
On logind's `PrepareForSleep` signal it runs `swaylock`, then releases the
inhibitor.

Sometimes that `swayidle` stops reacting to `PrepareForSleep` but keeps holding
the inhibitor. From then on, every suspend:

1. waits the full 30 s `InhibitDelayMaxSec` for the inhibitor,
2. suspends anyway, with no `swaylock`,

and logind logs:

```
Delay lock is active (UID 1000/<user>, PID 4740/swayidle) but inhibitor timeout is reached.
```

It stays like this until that `swayidle` is restarted. `budgie-daemon` does not
notice.

The mechanism was found on 2026-10-01: swayidle 1.9.0 can strand a
`PrepareForSleep` signal in sd-bus's internal queue. See
[`swayidle-dbus-fix/`](../swayidle-dbus-fix/README.md#cause). The same thing
happened to the `resume-display-on` listener, which has no `before-sleep`.

## Evidence (2026-09-27)

- Budgie's `swayidle` (PID 4740, running since the 2026-09-15 login) last ran
  `swaylock` on 2026-09-22 10:21. That was right after a lid close/open 7 ms
  apart. Every suspend after that logged the line above: eight in five days, no
  lock screen on any of them.
- Its inhibitor was far older than every other process's. The others
  re-acquired theirs after each resume; this one had not, so it wasn't getting
  logind's signals.
- No package changed around 2026-09-22 10:21–11:15. The 7 ms lid bounce is a
  likely trigger, since it produces sleep signals in quick succession, which is
  exactly what the queueing bug needs.
- Restarting it with identical arguments fixed it straight away:

| Suspend | Lid closed → `PM: suspend entry` | Lock screen on wake |
|---|---|---|
| 12:29, stuck `swayidle` | 31 s (inhibitor timeout) | no |
| 12:35, restarted | 1.1 s | yes |

## Fix

`~/.local/bin/swayidle-lock-guard` follows logind's journal for that exact line.
When the PID it names is one of this user's `swayidle` processes, it:

1. runs that process's `before-sleep` command (the lock screen) straight away,
   if it has one and it isn't already running. The system is about 1 s from
   suspending at that point, and this keeps the wake from showing an unlocked
   desktop;
2. restarts it:
   - the `resume-display-on` listener (its parent is
     `resume-display-on-listener`) is only killed, and its loop respawns it;
   - any other, such as Budgie's, is started again with **exactly the same
     arguments**, read from `/proc/<pid>/cmdline`. Its output goes to the
     journal as `budgie-swayidle`.

The first suspend after a process gets stuck still takes 30 s; later ones are
back to normal.

`budgie-daemon` isn't modified or diverted, and Budgie's arguments aren't
hard-coded. If `budgie-daemon` later runs `killall swayidle` and starts its own
instance again, nothing breaks.

It runs once per session (`flock`) and exits when the Wayland socket it started
with is gone.

## Install / remove

```
./install.sh --check   # report only
./install.sh           # install the script, add the autostart block, start it now
./uninstall.sh         # stop it, remove the block and the script
```

The labwc `autostart` is edited only inside the
`# >>> budgie-2604-setup:swayidle-lock-guard >>>` block, with a
`.bak-<timestamp>` backup. Requires read access to the system journal (membership of `adm`
or `systemd-journal`; the first user on Ubuntu is in `adm`); `install.sh`
checks this.

## Verify

```
pgrep -af swayidle-lock-guard
journalctl -t swayidle-lock-guard            # its own log, incl. every recovery
journalctl -b | grep 'inhibitor timeout'     # the symptom
```

Dry-run test without touching anything:

```
for P in $(pgrep -x swayidle); do
  echo "Delay lock is active (UID $(id -u)/$(id -un), PID $P/swayidle) but inhibitor timeout is reached."
done | SWAYIDLE_LOCK_GUARD_DRYRUN=1 ./bin/swayidle-lock-guard --stdin
```

## Manual recovery

Logging out and back in also fixes it, because it starts a fresh `swayidle`.

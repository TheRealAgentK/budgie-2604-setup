# resume-display-on

Turns the laptop panel back on after suspend/resume. Without it, coming back to
a laptop that went to sleep on its own leaves a **black screen that key presses
don't wake** — the machine is running, only the display outputs are off.

## Cause

Budgie's idle handling is a `swayidle` instance hardcoded in `budgie-daemon`:

| Idle | Action | On activity |
|---|---|---|
| 30 s | dim | undim |
| 300 s | `wlopm --off *` (outputs off) | `wlopm --on *` |
| before sleep | `swaylock` | — |
| 1200 s, on battery | logind `Suspend` | — |

The `resume wlopm --on *` belongs to swayidle's *idle timer* and only fires on
user activity while swayidle is still tracking that timeout. After a system
suspend it does not fire, so a suspend that follows the 5-minute `wlopm --off`
wakes with the outputs still off. A manual suspend never runs `wlopm --off`,
which is why suspending from the panel and waking works fine.

## Evidence (2026-09-13)

Same sequence twice — `wlopm --off *`, then `systemctl suspend`, then wake by
key press — with a delayed `wlopm --on` as a safety net:

| Test | Resumed | Outputs back on | By |
|---|---|---|---|
| Without listener | 16:07:20.590 | 16:07:44.821 (+24 s) | safety net only |
| With listener | 16:09:52.518 | 16:09:52.834 (+0.3 s) | `after-resume` listener |

## Fix

A second, minimal `swayidle` that does nothing except re-enable the outputs on
logind's resume signal:

```
swayidle after-resume 'wlopm --on \*' &
```

It runs alongside Budgie's instance and changes none of Budgie's behaviour.
`budgie-daemon` is not modified or diverted.

`budgie-daemon` runs `killall swayidle` when it starts and whenever it
reconfigures idle handling. That kills this listener too. The first version
started it bare from the autostart. On 2026-09-27 it turned out not to be
running at all: it had been killed at login.
`~/.local/bin/resume-display-on-listener` therefore runs it in a respawn loop
(2 s delay). The loop runs once per session (`flock`) and ends when the Wayland
socket it started with is gone.

## Install / remove

```
./install.sh --check   # report only
./install.sh           # install the loop script, add the autostart block, start it now
./uninstall.sh         # stop it, remove the block and the script
```

The labwc `autostart` is edited only inside the
`# >>> budgie-2604-setup:resume-display-on >>>` block, with a `.bak-<timestamp>`
backup.

## Verify

```
pgrep -af 'resume-display-on-listener|^swayidle after-resume'
pkill -f '^swayidle after-resume'; sleep 3; pgrep -af '^swayidle after-resume'   # respawned
```

## Not the cause (ruled out while debugging)

- **TCC battery profile brightness 1%** — deliberate; applied on every resume
  but readable.
- **`ACPI BIOS Error … PEG1.PEGP.EDP1` from `_Q14`/`_Q15`** — the firmware's
  brightness-key handlers reference a display on the discrete GPU, which is off
  in `intel` mode. Noisy but harmless; it shows up because keys get pressed at
  a dark screen.
- **NVIDIA suspend services disabled** — the NVIDIA driver is not loaded in
  `intel` mode, so they are irrelevant.

A block inhibitor (e.g. Brave's "Download in progress") makes the 20-minute
suspend fail while the outputs stay off. Same black screen, no sleep involved;
this listener does not cover that case. Check with `systemd-inhibit --list`.

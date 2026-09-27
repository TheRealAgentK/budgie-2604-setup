# charge-limit-alert

Warns you to **unplug the charger at 80 %**, because this laptop can't stop
charging by itself. It can also switch a smart plug off, which gives you a real
cutoff.

The watcher is called `charge-guard` and runs as a systemd user service.

## Why it is needed

TUXEDO Control Center has a charging profile setting. **Stationary** is meant
to hold the battery below a full charge. On this board (`PHxARX1_PHxAQF1`, BIOS
`N.1.05A08`) the setting reaches the embedded controller but has no effect:

- TCC and `tuxedo-drivers` write the profile correctly. EC register `0x07A6`
  reads back `0x20` (stationary), and the feature bit at `0x078E` is set.
- A full logged charge cycle with stationary active the whole time charged to
  **6400 mAh, 100 % of design capacity**. The cells held **4.21–4.22 V**, a
  full-charge voltage. No reduced plateau, and the gauge isn't re-scaled.
- `BAT0` has no `charge_control_end_threshold`. The EC has no `CGLM` field at
  `0x07B9` (that's where the Gen10 charge-threshold patch expects it), and BIOS
  setup has no FlexiCharger.

Raw logs, plots and the write-up for
[tuxedo-control-center#268](https://github.com/tuxedocomputers/tuxedo-control-center/issues/268)
are in `~/code/kai/tuxedo-charge-test/`.

So software can't limit charging on this machine. It can only tell you when to
unplug, or switch off a plug it controls.

## What it does

Every `POLL` seconds (default 30) it reads `BAT0` and checks whether a charger
is connected:

| Situation | Action |
|---|---|
| Charger connected and battery ≥ `LIMIT` (80 %) | critical notification; runs `AT_LIMIT_CMD` |
| Still over the limit `REPEAT_MIN` (10) minutes later | notifies again |
| Charger removed, or battery ≤ `RESUME` (75 %) | "Charging stopped" notification; runs `BELOW_RESUME_CMD` |

"Charger connected" means any of these:

- the barrel-jack supply (`AC0`, type `Mains`) reports online;
- a USB-C supply (`ucsi-source-psy-*`, type `USB`) reports online;
- the battery status is anything but `Discharging`.

The battery check covers a USB-C charger that doesn't show up as an online
supply. As of 2026-09-27, `AC0` has only been checked on the barrel jack.

Notifications replace each other instead of stacking up. Log lines go to the
journal.

## Settings

`~/.config/budgie-2604-setup/charge-guard.conf` is plain shell syntax. The
repo default is `config/charge-guard.conf`. `install.sh` creates the file only
if it's missing and never overwrites your edits. The script checks the values
when it starts: whole numbers, `RESUME` below `LIMIT`, `POLL` of at least 1.

To apply changes:

```
systemctl --user restart charge-guard
```

**Smart-plug cutoff.** Set `AT_LIMIT_CMD` to switch the plug off and
`BELOW_RESUME_CMD` to switch it back on. Any command that `sh` can run works;
the config file has Tasmota, Shelly/HTTP and Kasa examples. The hooks run once
per episode, not on every re-warning.

## Install / remove

```
./install.sh --check     # report only
./install.sh             # install script, settings (if missing) and unit; enable and start
./uninstall.sh           # stop, disable, remove unit and script; keep settings
./uninstall.sh --purge   # ...and move the settings to a .bak-<timestamp> copy
```

Installs to:

- `~/.local/bin/charge-guard`
- `~/.config/systemd/user/charge-guard.service` (`WantedBy=default.target`)

Budgie's labwc session doesn't activate `graphical-session.target`, so the unit
doesn't depend on it. The user bus is already up when `default.target` starts.

## Verify

```
systemctl --user status charge-guard
charge-guard --once      # battery %, status, "on power", limit, resume
charge-guard --test      # send a test notification
journalctl --user -u charge-guard
```

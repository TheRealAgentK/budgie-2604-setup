# Display resolution / scaling consistency

Keeps the internal panel and the login screen at a consistent effective size on
the Budgie / **labwc** Wayland session.

## Desired state

| Where | Setting |
|---|---|
| Budgie session, `eDP-1` | `2304x1440` @ `90 Hz`, scale `1.0` |
| SDDM login screen | native `2880x1800`, theme UI scale `1.25` |

`2880 / 1.25 = 2304`, `1800 / 1.25 = 1440` — so the login screen and the session
present controls at the same physical size, without forcing a custom modeline
into SDDM/Xorg (which was tried and did not hold — see
[main README, "Removed experiments"](../README.md)).

## Why kanshi

The labwc session does not reliably keep `eDP-1` at `2304x1440@90` across login,
output reconfiguration and resume. [`kanshi`](https://sr.ht/~emersion/kanshi/)
watches Wayland output state and reapplies a declared profile whenever it
changes.

Profile — `~/.config/kanshi/config` (`config/kanshi.config` here):

```
profile {
    output eDP-1 enable mode 2304x1440@90Hz position 0,0 scale 1
}
```

kanshi is launched from the labwc autostart. `install.sh` manages a clearly
marked block there and leaves everything else in the file alone:

```
# >>> budgie-2604-setup:display-scaling >>>
# Keep laptop display at 2304x1440 @ 90 Hz, scale 1.0  (managed by budgie-2604-setup/display-scaling)
kanshi &
# <<< budgie-2604-setup:display-scaling <<<
```

## SDDM

The login-screen scale lives in the slickSDDM theme config
(`/usr/share/sddm/themes/ubuntu-budgie-login/theme.conf`, `[General] scale`).
It is read/written through the packaged helper rather than by editing the file:

```sh
sudo slicksddm-customize --set "General/scale=1.25"
slicksddm-customize --get "General/scale"        # -> 1.25
```

`uninstall.sh` resets it to `1.0` (the value in `theme.conf.example`).

## Install

```sh
./install.sh            # apply (idempotent; safe to re-run)
./install.sh --check    # report state only, change nothing
```

Needs `sudo` only when something actually has to change (installing `kanshi`,
writing the SDDM scale).

## Uninstall

```sh
./uninstall.sh
```

Removes the autostart block, removes `~/.config/kanshi/config` if it still
matches the repo copy, resets the SDDM scale to `1.0`, and stops a running
kanshi. The `kanshi` package is left installed.

## Verify

```sh
wlr-randr | grep -A1 'eDP-1 "'      # 2304x1440 ... (current), Scale: 1.000000
pgrep -a kanshi                     # running
slicksddm-customize --get General/scale   # 1.25
```

# SDDM login-screen scaling

- **Display manager:** SDDM
- **Theme:** `ubuntu-budgie-login` (slickSDDM-based)
- **Tool:** `slicksddm-customize` (writes the theme's `theme.conf`)

## Live value (verified read-only 2026-09-08)

```
slicksddm-customize --get "General/scale"   ->  1.25
/usr/share/sddm/themes/ubuntu-budgie-login/theme.conf : line 11  scale = 1.25
```

So the login screen is scaled **1.25**, independent of the desktop-session
scale. This keeps the login UI at roughly the same effective size as the
session (native panel `2880x1800`, `2880 / 1.25 = 2304`).

## Applying (documentation only — not run here)

```sh
sudo slicksddm-customize --set "General/scale=1.25"
slicksddm-customize --get "General/scale"      # verify
```

Do not hand-edit the tool-generated `theme.conf`; use `slicksddm-customize`.
The `display-scaling/` component's `install.sh` already manages this setting
(alongside the kanshi output profile).

## Note on the TUXEDO handoff value

The "Persistent Fixes" handoff quoted `General/scale=1.5`. The live machine is
at **`1.25`**, set via the same tool. `1.25` is what is documented and managed
here; `1.5` was not found on the system.

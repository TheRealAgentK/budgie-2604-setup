# Hibernate support in Budgie 26.04

## Problem

The kernel and swap were already configured for hibernation, but Budgie stopped
offering **Hibernate** because, for the desktop user,
`systemd-logind`'s `CanHibernate` returned `no` (root got `yes`). The old
legacy PolicyKit `.pkla` file was no longer honoured on Ubuntu 26.04.

## Fix

A native PolicyKit **JavaScript rule** granting the four `login1` hibernate
actions to a local, active session belonging to the `sudo` group.

Live path: `/etc/polkit-1/rules.d/10-enable-hibernate.rules`
Repo copy: [`10-enable-hibernate.rules`](10-enable-hibernate.rules)

> **Source note:** `/etc/polkit-1/rules.d/` is root-readable only. This session
> operated read-only and did not authenticate `sudo`, so the repo copy is the
> **known-working content from the setup handoff**, not a byte capture of the
> live file. The functional check below *was* run and passes, which is
> consistent with this rule being active. To replace the repo copy with the
> exact live bytes, from a real terminal:
> `sudo cat /etc/polkit-1/rules.d/10-enable-hibernate.rules`

## Obsolete file — do NOT recreate

The legacy rule was removed once the JS rule worked:

```
/etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla
```

Do not recreate it. (Its absence could not be confirmed this session — the
directory is root-only — but the handoff records it as removed and hibernation
works via the JS rule.)

## Swap / resume — DO NOT MODIFY

Hibernation depends on an existing, correctly-offset swapfile. Verified
2026-09-08:

| | |
|---|---|
| Swapfile | `/swapfile`, 64 GiB, `root:root`, mode `0600` |
| `swapon --show` | `/swapfile` (file, 64G, prio -1) **and** `/dev/nvme0n1p3` (partition, 8G) |
| Kernel cmdline | `resume=UUID=34729833-c7b4-4ac6-b035-0a7a66ac6284` `resume_offset=135194624` |

- `/swapfile` is the hibernation target. **Never** recreate, resize, move,
  defragment, `fallocate`, or `cp` it — that can change the physical
  `resume_offset` and silently break resume.
- `nvme0n1p3` (8 GiB) is ordinary swap, **not** the hibernation target. Leave
  it alone.
- This repo intentionally ships **no** swap/resume tooling.

## Installing on another machine (documentation only — not run here)

```sh
sudo install -m 0644 -o root -g root \
    10-enable-hibernate.rules /etc/polkit-1/rules.d/10-enable-hibernate.rules
# remove any legacy rule:
sudo rm -f /etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla
# reboot (or restart polkit + re-login), then verify CanHibernate -> yes
```

Adjust the group (`sudo` vs `wheel`) and the swap/resume setup to the target
system first.

## Verify (read-only)

```sh
./verify.sh
```

Runs `busctl … CanHibernate` (expect `s "yes"`), prints the kernel `resume*`
args and `swapon --show`, and diffs the repo rule against the live file **only
if it is readable without privilege escalation** (normally it is not).

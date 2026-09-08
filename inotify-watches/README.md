# Increased inotify watch limit

## What

A sysctl drop-in raising the per-user inotify watch limit:

```
fs.inotify.max_user_watches = 1000000
```

Live path: `/etc/sysctl.d/60-inotify.conf`
Repo copy: [`60-inotify.conf`](60-inotify.conf) (byte-identical, 38 bytes)

## Why

The higher limit had previously existed only inside an old configuration
backup. During the Ubuntu 26.04 setup it was re-established as a proper sysctl
drop-in rather than left buried in a backup. It matters for tools that watch
many files (IDEs / language servers, file-sync clients, bundlers/watchers);
the stock limit is far lower and causes "too many open files" / missed
change events.

## Live state (verified 2026-09-08 — do not re-apply)

| | |
|---|---|
| File | `/etc/sysctl.d/60-inotify.conf`, `root:root`, mode `0644` |
| Running value | `sysctl fs.inotify.max_user_watches` → `1000000` |

## Installing on another machine (documentation only — not run here)

```sh
sudo install -m 0644 -o root -g root 60-inotify.conf /etc/sysctl.d/60-inotify.conf
sudo sysctl --system            # or reboot
sysctl fs.inotify.max_user_watches   # expect: 1000000
```

## Verify (read-only)

```sh
./verify.sh
```

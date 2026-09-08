# nvidia-detector compatibility shim

## Problem

`mate-optimus` (the MATE/Budgie Optimus applet) invokes **`nvidia-detector`** to
decide whether an NVIDIA GPU is present. On Ubuntu 26.04 the Ubuntu package that
used to provide that command no longer does, so `mate-optimus` can't detect the
discrete GPU.

## Fix

A minimal shell shim at `/usr/local/bin/nvidia-detector` that reproduces the
only behaviour `mate-optimus` needs: print `nvidia` if a PCI display-class
device with NVIDIA's vendor ID is present, otherwise print `none`. Always exits
`0`.

It is **deliberately not** package-management logic — it just scans
`/sys/bus/pci/devices/*/`.

## This machine

```
GPU:        NVIDIA GA107M [GeForce RTX 3050 Ti Mobile]  [10de:25a0]  (PCI class 0x0302)
iGPU:       Intel Alder Lake-P Iris Xe                  [8086:46a6]
mate-optimus: 21.04.0-1build1 (installed)
prime-select: present
```

The shim matches on vendor `0x10de` and PCI class prefix `0x03` (covers both
`0x0300` VGA and `0x0302` 3D-controller), so it reports `nvidia` correctly here.

## Live install (verified 2026-09-08 — do not re-apply)

| Property | Value |
|---|---|
| Path | `/usr/local/bin/nvidia-detector` |
| Owner / mode | `root:root` / `0755` |
| Size | 303 bytes |
| SHA-256 | `1e542017e373111fea565f7c665bdac99132c6f0f80256023619e0d2b7e4e106` |
| Package-owned | no (`dpkg -S` finds nothing) |

The repo copy `nvidia-detector` is byte-identical to the live file (same
SHA-256).

## Installing on another machine (documentation only — not run here)

```sh
sudo install -m 0755 -o root -g root nvidia-detector /usr/local/bin/nvidia-detector
nvidia-detector          # expect: nvidia   (on a machine with an NVIDIA dGPU)
```

## Verify (read-only)

```sh
./verify.sh
```

Compares the repo copy against the live file (SHA-256), prints owner/mode, and
runs the live shim.

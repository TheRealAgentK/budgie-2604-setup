#!/bin/bash
# Read-only. Compares the repo shim with the live /usr/local/bin/nvidia-detector.
# Makes no changes.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
LIVE=/usr/local/bin/nvidia-detector
REPO="$HERE/nvidia-detector"
KNOWN_SHA=1e542017e373111fea565f7c665bdac99132c6f0f80256023619e0d2b7e4e106

echo "repo copy : $REPO"
echo "live copy : $LIVE"
echo

if [ ! -e "$LIVE" ]; then
    echo "[MISS] $LIVE not present"
    exit 1
fi

echo "owner/mode: $(stat -c '%U:%G %a' "$LIVE")   (expect root:root 755)"
lsha=$(sha256sum "$LIVE" | cut -d' ' -f1)
rsha=$(sha256sum "$REPO" | cut -d' ' -f1)
echo "live  sha : $lsha"
echo "repo  sha : $rsha"
echo "known sha : $KNOWN_SHA"
[ "$lsha" = "$KNOWN_SHA" ] && echo "  [ ok ] live matches known-good" || echo "  [WARN] live differs from known-good"
[ "$lsha" = "$rsha" ]      && echo "  [ ok ] live matches repo copy"   || echo "  [WARN] live differs from repo copy"

echo
echo "live output: $("$LIVE")   (expect: nvidia on this machine)"

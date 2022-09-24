#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <image> <device>" >/dev/stderr
    echo "" >/dev/stderr
    echo "Where <image> is some .img you'd pass to dd if=<image>" >/dev/stderr
    echo "and <device> is a usb drive (be careful and look at 'lsblk' to figure this out!)" >/dev/stderr
    exit 1
fi

diskImage=$1
device=$2

sudo dd bs=4M if="$diskImage" of="$device" status=progress conv=fsync

# TODO: Figure out if there's some way of getting nix's `boot.growPartition` and
# `filesystems."/".autoResize` settings to work with encrypted volumes. They
# work great with un-encrypted volumes.
sudo tools/grow-encrypted-last-partition.sh "$device"

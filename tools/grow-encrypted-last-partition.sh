#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <dev>"
    exit 1
fi
DEVICE=$1

CRYPT_DEVICE=""
function finish {
    if [ -n "$CRYPT_DEVICE" ]; then
        sudo cryptsetup close "$(basename "$CRYPT_DEVICE")"
    fi
}
trap finish EXIT

read -r -s -p "Enter passphrase for root filesystem: " PASSPHRASE
echo ""

set +e
sudo growpart "$DEVICE" 2
growpart_retval=$?
set -e

if [ $growpart_retval -eq 0 ]; then
    : # noop
elif [ $growpart_retval -eq 1 ]; then
    # From `man growpart`:
    #  > The exit status is 1 if the partition could not be grown due to lack of available space.
    echo "Could not grow the encrypted partition any further. I'll go on to try to grow the decrypted partition and then the filesystem."
else
    exit 1
fi

CRYPT_DEVICE=cryptroot-resizing
echo -n "$PASSPHRASE" | sudo cryptsetup -q luksOpen --key-file=- "${DEVICE}2" "$CRYPT_DEVICE"
echo -n "$PASSPHRASE" | sudo cryptsetup -q resize --key-file=- "$CRYPT_DEVICE"
sudo resize2fs /dev/mapper/cryptroot-resizing

echo "Successfully resized ${DEVICE}!"

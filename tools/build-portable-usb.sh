#!/usr/bin/env bash

set -euo pipefail

# Some of this came from nixos/lib/make-disk-image.nix. It might be possible to
# use that code rather than copying it into here.

LOOP_DEVICE=""
CRYPT_DEVICE=""
function finish {
    sudo umount /mnt/boot || true
    sudo umount /mnt || true

    if [ -n "$LOOP_DEVICE" ]; then
        sudo losetup -d "$LOOP_DEVICE"
    fi

    if [ -n "$CRYPT_DEVICE" ]; then
        sudo cryptsetup close "$(basename "$CRYPT_DEVICE")"
    fi
}
trap finish EXIT

bootSize=256M
totalSize=$((16 * 1024))M
diskImage=/tmp/build.img

promptPassword() {
    while true; do
        read -r -s -p "Enter passphrase for root filesystem: " password
        echo >/dev/stderr
        read -r -s -p "Verify passphrase: " password2
        echo >/dev/stderr
        [ "$password" = "$password2" ] && break
        echo "Passphrases didn't match. Please try again." >/dev/stderr
    done
    echo -n "$password"
}

createEmptyImage() {
    rm -rf "$diskImage"
    truncate -s $totalSize $diskImage
    parted --script $diskImage -- \
        mklabel gpt \
        mkpart ESP fat32 8MiB $bootSize \
        set 1 boot on \
        mkpart primary ext4 $bootSize -1

    LOOP_DEVICE=$(sudo losetup -Pf --show /tmp/build.img)

    # Format boot partition.
    sudo mkfs.fat -F 32 "${LOOP_DEVICE}p1"
    sudo fatlabel "${LOOP_DEVICE}p1" NIXBOOT

    CRYPT_DEVICE=/dev/mapper/cryptroot-usb
    echo -n "$PASSPHRASE" | sudo cryptsetup -q luksFormat --key-file=- "${LOOP_DEVICE}p2"
    echo -n "$PASSPHRASE" | sudo cryptsetup luksOpen --key-file=- "${LOOP_DEVICE}p2" "$(basename "$CRYPT_DEVICE")"
    sudo mkfs.ext4 "$CRYPT_DEVICE" -L NIXROOT
}

mountImage() {
    sudo mount "$CRYPT_DEVICE" /mnt
    sudo mkdir -p /mnt/boot
    sudo mount "${LOOP_DEVICE}p1" /mnt/boot
}

nixInstall() {
    local node=$1
    local bootDeviceUuid
    bootDeviceUuid=$(lsblk -no UUID "${LOOP_DEVICE}p1")
    local encryptedRootDeviceUuid
    encryptedRootDeviceUuid=$(sudo blkid -o value -s UUID "${LOOP_DEVICE}p2")
    local decryptedRootDeviceUuid
    decryptedRootDeviceUuid=$(sudo blkid -o value -s UUID "$CRYPT_DEVICE")
    drv=$(colmena eval --config hive.nix --instantiate -E "
        { nodes, pkgs, ... }:

        (pkgs.toLiveUsb {
          node = nodes.$node;
          encryptedRootDevice = \"/dev/disk/by-uuid/$encryptedRootDeviceUuid\";
          decryptedRootDevice = \"/dev/disk/by-uuid/$decryptedRootDeviceUuid\";
          bootDevice = \"/dev/disk/by-uuid/$bootDeviceUuid\";
        }).config.system.build.toplevel
    ")
    system=$(nix-build --no-out-link "$drv")
    sudo nixos-install --root /mnt --system "$system" --no-root-password
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <node>"
    exit 1
fi
node=$1

PASSPHRASE=$(promptPassword)
createEmptyImage
mountImage
nixInstall "$node"

echo "Successfully built $diskImage for: $node"
echo ""
echo "To put this on a usb drive, insert your drive, *carefully* look at lsblk"
echo "to find the correct device, and run dd:"
echo ""
echo "    sudo dd bs=4M if=$diskImage of=<DEVICE HERE> status=progress conv=fsync"

# Figure out if there's some way of getting nix's `boot.growPartition` and
# `filesystems."/".autoResize` settings to work with encrypted volumes. They
# work great with un-encrypted volumes.
echo ""
echo "Finally, resize the root partition to occupy all the available space:"
echo ""
echo "    sudo growpart <DEVICE HERE> 2"
echo "    sudo cryptsetup luksOpen <DEVICE HERE>2 cryptroot-resizing"
echo "    sudo cryptsetup resize cryptroot-resizing"
echo "    sudo resize2fs /dev/mapper/cryptroot-resizing"
echo "    sudo cryptsetup close cryptroot-resizing"

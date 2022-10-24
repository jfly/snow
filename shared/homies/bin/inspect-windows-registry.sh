#!/usr/bin/env nix-shell
#!nix-shell -i bash -p chntpw
# shellcheck shell=bash

set -e

# Instructions copied from
# https://unix.stackexchange.com/questions/255509/bluetooth-pairing-on-dual-boot-of-windows-linux-mint-ubuntu-stop-having-to-p/255510#255510.
mount /dev/nvme0n1p3 /mnt
cp /mnt/Windows/System32/config/SYSTEM /tmp/SYSTEM
umount /mnt

echo "I'm opening up a copy of the Windows registry for you"
echo "If you're looking for bluetooth keys, I suggest running the following command:"
echo ' > cd ControlSet001\Service\BTHPORT\Parameters\Keys'
echo ""
chntpw -e /tmp/SYSTEM

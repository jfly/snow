#!/usr/bin/env bash

set -euo pipefail

hostname=aragorn

# First, check if the version currently installed/running is already up to date?
desired_nix_version=$(nix eval .#my-router --raw --apply 'r: r.hack-nix-version')
actual_nix_version=$(ssh "$hostname" cat /etc/nix-build-version)
if [ "$desired_nix_version" = "$actual_nix_version" ]; then
	echo "It looks like $hostname is already up to date (running $actual_nix_version). Not doing anything to it!"
	exit 0
fi

echo "It looks $hostname is running the wrong version of stuff (ddesired $desired_nix_version, running: $actual_nix_version)"

# Basically copying
# https://openwrt.org/docs/guide-user/installation/sysupgrade.cli#command-line_instructions

nix build .#my-router
DEST_FILENAME=/tmp/firmware_image-sysupgrade.bin
scp -O result/*-sysupgrade.bin "$hostname":$DEST_FILENAME
ssh "$hostname" sysupgrade -v -n $DEST_FILENAME

#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <node name>"
    exit 1
fi

node_name=$1

# Build.
drv=$(colmena eval --instantiate -E "{nodes, pkgs, ...}: (pkgs.toRpiSdCard { node=nodes.$node_name; inherit pkgs; }).config.system.build.sdImage")
nix-build "$drv"

# Identify image name.
image=$(realpath result/sd-image/*.img.zst)

# Tell people how to copy.
echo "I've generated nixos-sd-image.img for you. Now copy it to an sdcard and put it in a Raspberry PI:"
echo ""
echo "zstdcat '${image}' | sudo dd bs=4M iflag=fullblock of=</dev device> conv=fsync oflag=direct status=progress"

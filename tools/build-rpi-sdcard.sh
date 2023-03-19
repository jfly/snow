#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <node name>"
    exit 1
fi

node_name=$1

# Build
drv=$(colmena eval --impure --instantiate -E "{nodes, pkgs, ...}: (pkgs.toRpiSdCard { node=nodes.$node_name; inherit pkgs; }).config.system.build.sdImage")
nix-build "$drv"

# Extract
nix-shell -p zstd --run "unzstd result/sd-image/*.img.zst -o nixos-sd-image.img"

# Copy
echo "I've generated nixos-sd-image.img for you. Now copy it to an sdcard and put it in a Raspberry PI:"
echo ""
echo "sudo dd bs=4M if=nixos-sd-image.img of=</dev device> conv=fsync oflag=direct status=progress"

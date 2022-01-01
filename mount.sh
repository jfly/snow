#!/usr/bin/env bash

mkdir -p remote-nixos
sshfs --debug -o allow_root,reconnect -o sftp_server="/run/wrappers/bin/sudo -u root /nix/store/2qb32vc3g91rvv83myywzzrgmgaimf03-openssh-8.8p1/libexec/sftp-server" dallben:/ remote-nixos

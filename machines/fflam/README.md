Our backup NAS running on a ThinkCentre M710.

## Bootstrapping

1. Enable boot on power loss in BIOS.
2. Follow instructions in ../README.md.

## Unlock on boot

We have full disk encryption enabled for this machine. If it reboots, you must
manually unlock it:

```console
torsocks ssh -t "root@$(clan vars get fflam tor-hidden-service/hostname)" systemd-tty-ask-password-agent --query
```

The root password is available at `clan vars get fflam rootfs/password`.

Note: this requires the `tor` service to be running (see `machines/pattern/tor.nix`).

## Adding another drive

See [zfs/README.md](../../nixos-modules/zfs/README.md).

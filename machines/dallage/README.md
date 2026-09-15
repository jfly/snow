# `dollage`

Kodi running on NixOS.

## Provision

1. See [../README.md](../README.md).
2. Make sure you've maxed out the volume with `alsamixer`: ssh to the machine,
   `sudo machinectl shell kodi@`, `alsamixer`.
3. Pair with gurgi: `moonlight` (frustratingly, this probably requires a
   keyboard and a mouse).
3. Follow instructions in `nixos-modules/kodi-colusita/README.md` to finish
   bootstrapping.
4. Confirm bluetooth works. Pair devices if necessary.

## Unlock on boot

We have full disk encryption enabled for this machine. If it reboots, you must
manually unlock it:

```console
unlock dallage
```

Note: this requires the `tor` service to be running (see `machines/pattern/tor.nix`).

clark is an Intel NUC I bought years ago. He has worn many hats over the years:
HTPC, NAS, Kubernetes cluster. Now he is a
[Tang](https://github.com/latchset/tang) keyserver.

## Bootstrapping

1. Enable boot on power loss in BIOS.
2. Follow instructions in ../README.md.

## Unlock on boot

We have full disk encryption enabled for this machine. If it reboots, you must
manually unlock it:

```console
torsocks ssh -t "root@$(clan vars get clark tor-hidden-service/hostname)" systemd-tty-ask-password-agent --query
```

The root password is available at `clan vars get clark rootfs/password`.

Note: this requires the `tor` service to be running (see `machines/pattern/tor.nix`).

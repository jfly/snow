Our backup NAS running on a ThinkCentre M710.

## Bootstrapping

1. Enable boot on power loss in BIOS.
2. Follow instructions in ../README.md.

## Unlock on boot

We have full disk encryption enabled for this machine. If it reboots, you must
manually unlock it:

```console
torsocks ssh -t "root@$(clan vars get fflam tor-hidden-service/hostname)" systemctl restart systemd-cryptsetup@crypted.service
```

The root password is available at `clan vars get fflam rootfs/password`.

Note: this requires the `tor` service to be running (see `machines/pattern/tor.nix`).

## Adding another drive

Connect the new drive. Find it in `lsblk`. The rest of this example will be for `/dev/sda`.

    nix-shell -p parted
    DRIVE=/dev/sda
    parted "$DRIVE" -- mklabel gpt
    parted -a optimal "$DRIVE" -- mkpart primary ext4 0% 100%
    mkfs.ext4 "${DRIVE}1"

Get the UUID of the partition you just created (I use `lsblk -f "${DRIVE}1"`).
Add it to `nasDriveUuids` in `nas.nix`.

(If this is a brand new array, you might want to play with the permissions of the root folder)

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

Create a single partition that fills the whole disk (this isn't strictly
necessary, but probably plays more nicely with other tooling):

```console
nix-shell -p parted
DRIVE=/dev/sda
parted "$DRIVE" -- mklabel gpt
parted -a optimal "$DRIVE" -- mkpart primary ext4 0% 100%
```

Now add that drive to the pool (if the pool doesn't exist yet, see next command):

```
bcachefs device add --rotational /dev/disk/by-uuid/5dc8ec0c-cd70-4549-bd91-adca08356225 "${DRIVE}1"
```

If creating a new pool (you may want to change the permissions of the root
folder after this):

```
bcachefs format --encrypted --metadata_replicas=2 --rotational "${DRIVE}1"
```

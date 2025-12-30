# fflewddur

Our primary NAS running on that old gaming PC James gave me forever ago.

## Bootstrapping

1. F12 while booting. Enter BIOS Setup > BIOS Features
   - Boot Mode Selection: UEFI only
   - LAN PXE Boot Option ROM: Disabled
   - Storage Boot Option Control: UEFI Only
   - F10 to save and exit
2. Follow instructions in ../README.md.
3. Set passwords for samba users.
   ```console
   $ sudo smbpasswd -a jfly
   $ sudo smbpasswd -a rachel
   ```
   TODO: manage this declaratively. See
   https://github.com/kanidm/kanidm/issues/2627 and
   https://github.com/lldap/lldap/issues/599 for promising options. If they don't
   work out, perhaps NixOS would accept a `passwordFile` option.

## Adding another drive

Connect the new drive. Find it in `lsblk`. The rest of this example will be for `/dev/sda`.

    nix-shell -p parted
    DRIVE=/dev/sda
    parted "$DRIVE" -- mklabel gpt
    parted -a optimal "$DRIVE" -- mkpart primary ext4 0% 100%
    mkfs.ext4 "${DRIVE}1"

Get the UUID of the partition you just created (I use `lsblk -f "${DRIVE}1"`).
Add it to `nasDriveUuids` in `nas.nix`.

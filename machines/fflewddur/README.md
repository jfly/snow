Our primary NAS running on that old gaming PC James gave me forever ago.

## Bootstrapping ##

Build a custom live cd:

    $ cd livecd
    # edit `networking.hostName` in iso.nix
    # make sure you have a nixos channel pointing at something stable like 21.11:
        nix-channel --add https://nixos.org/channels/nixos-21.11 nixos
        nix-channel --update
    $ nix-build '<nixos/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix
    $ sudo dd if=./result/iso/nixos-21.11.334984.08370e1e271-x86_64-linux.iso of=USB_DEVICE_HERE status=progress conv=fsync

1. Insert live USB drive you just created.
1. F12 while booting. Enter BIOS Setup > BIOS Features
   - Boot Mode Selection: UEFI only
   - LAN PXE Boot Option ROM: Disabled
   - Storage Boot Option Control: UEFI Only
   - F10 to save and exit
3. F12 while booting. Select "UEFI: CBM", then the regular NixOS Installer.

The machine should boot up, and you should be able to ssh to it:

    $ ssh root@fflewddur
    # Partition
    $ parted /dev/sda -- mklabel gpt
    $ parted /dev/sda -- mkpart primary 512MiB -0
    $ parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
    $ parted /dev/sda -- set 2 esp on
    # Format
    $ mkfs.ext4 -L nixos /dev/sda1
    $ mkfs.fat -F 32 -n boot /dev/sda2
    # Install
    $ mount /dev/disk/by-label/nixos /mnt
    $ mkdir /mnt/boot
    $ mount /dev/disk/by-label/boot /mnt/boot
    $ nixos-generate-config --root /mnt
    # Hack on /mnt/etc/nixos/configuration.nix:
    #  - Change `networking.hostName` to "fflewddur".
    #  - Add `services.openssh.enable = true;`
    #  - Add `users.users.root.openssh.authorizedKeys.keys`
    $ nixos-install --no-root-passwd
    $ reboot

## Deploying ##

    ./deploy fflewddur

## Adding another drive ##

Connect the new drive. Find it in `lsblk`. The rest of this example will be for `/dev/sda`.

    nix-shell -p parted
    DRIVE=/dev/sda
    parted "$DRIVE" -- mklabel gpt
    parted -a optimal "$DRIVE" -- mkpart primary ext4 0% 100%
    mkfs.ext4 "${DRIVE}1"

Get the UUID of the partition you just created (I use `lsblk -f /dev/sda1`).
Add it to `nasDriveUuids` in `nas.nix`.

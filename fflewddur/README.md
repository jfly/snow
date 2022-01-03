Our primary NAS running on that old gaming PC James gave me forever ago.

## Bootstrapping ##

I tried out PXE booting this time. pixiecore is a pretty slick all-in-one tool!

1. Start pixiecore on another machine on the same network: `sudo pixiecore quick xyz --dhcp-no-bind`
2. F12 while booting. Enter BIOS Setup > BIOS Features
   - Boot Mode Selection: UEFI and Legacy - UEFI netboot just doesn't seem to work for some reason
   - LAN PXE Boot Option ROM: Enabled
   - F10 to save and exit
3. F12 while booting. Select "Realtek PXE B05 D00"
4. If that works, you'll be looking at the netboot.xyz menu. Go to Distributions > Linux Network Installs > NixOS > nixos-21.11

Now on the freshly booted machine:

    $ mkdir ~/.ssh
    $ curl https://github.com/jfly.keys > ~/.ssh/authorized_keys

At this point, you can continue from a laptop by doing `ssh nixos@nixos`.

    # Partition
    $ sudo su
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
    # Hack on /mnt/etc/nixos/configuration.nix to change it to an EFI boot loader
    # Also change the hostname to "fflewddur"
    $ nixos-install --no-root-passwd
    $ reboot

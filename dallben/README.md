Customized Kodi running on NixOS.

https://docs.google.com/document/d/1LtwhNzlWBPv61b5ysdFDaDuw3bote0nc9ObSiC2ZJ7s/

## Bootstrapping Intel NUC ##

First, change some BIOS settings.

- Update bios. https://wiki.archlinux.org/title/Intel_NUC links to
  instructions for the "Visual BIOS", but we actually have the "Aptio
  BIOS":
  https://www.intel.com/content/www/us/en/download/19485/bios-update-fncml357.html
- F2 while booting to get into the BIOS
- Bios > Boot > Secure Boot > Secure Boot: Set to "Disabled"
- Bios > Performance > Cooling > Fan Control Mode: Set to "Quiet"
- Bios > Power > Power > After Power Failure: Set to "Power On"
- Bios > Advanced > Onboard Devices > HDMI CEC Control: Uncheck this box!
  (the Pulse-Eight adapter doesn't play nicely with this setting. See
  https://github.com/Pulse-Eight/libcec/issues/445.)

Now set up a USB drive, and boot from it with ethernet connected.

    $ wget https://channels.nixos.org/nixos-21.11/latest-nixos-minimal-x86_64-linux.iso
    $ sudo dd bs=4M if=./latest-nixos-minimal-x86_64-linux.iso of=/dev/sda conv=fsync oflag=direct status=progress

Now on the freshly booted machine.

    $ mkdir ~/.ssh
    $ curl https://github.com/jfly.keys > ~/.ssh/authorized_keys

At this point, you can continue from a laptop by doing `ssh nixos@nixos`.

    # Partition
    $ sudo su
    $ parted /dev/nvme0n1 -- mklabel gpt
    $ parted /dev/nvme0n1 -- mkpart primary 512MiB -0
    $ parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
    $ parted /dev/nvme0n1 -- set 2 esp on
    # Format
    $ mkfs.ext4 -L nixos /dev/nvme0n1p1
    $ mkfs.fat -F 32 -n boot /dev/nvme0n1p2
    # Install
    $ mount /dev/disk/by-label/nixos /mnt
    $ mount /dev/disk/by-label/boot /mnt/boot
    $ nixos-generate-config --root /mnt
    $ nixos-install
    $ reboot

## Deploying ##

I don't want to take the time to figure out a good secrets management solution,
so we're doing something simple right now:

    git clone <this repo>
    cd snow
    cp dallben/secrets.nix.example dallben/secrets.nix
    # edit dallben/secrets.nix!

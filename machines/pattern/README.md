# pattern

My daily driver laptop.

## Bootstrapping

1. Install the nixos configuration.
   - TODO: adopt disko
2. How to set up Syncthing/VPN/SSH?
3. Set up email:
   ```console
   $ oama authorize google jeremyfleischman@gmail.com
   ```

## Disaster recovery

If you have no working dev machines to bootstrap from, here's how to do it.

1. Set up a nixos live usb environment using an ISO from <https://nixos.org/download/>
2. [Enable flakes](https://wiki.nixos.org/wiki/Flakes#Nix_standalone)
3. Enter devshell for this repo:
  ```console
  $ git clone https://github.com/jfly/snow.git
  $ cd snow
  $ nix develop
  ```
4. Update `disko.devices.disk.main.device` in `machines/pattern/configuration.nix`.
5. Deploy to localhost with:
   ```console
   $ sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko/latest#disko-install -- --write-efi-boot-entries --flake github:jfly/snow#pattern --disk main /dev/sda
   ```

   (`clan machines install ...` doesn't work because it wants to decrypt
   secrets, which may be challenging to do depending on how much of a disaster
   you're recovering from.)

   Note: this will almost certainly crash pretty quickly by running out of disk
   space (the tmpfs for `/nix/.rw-store` will be half of physical ram, which
   probably isn't enough to build the system closure).

   To get more space, make a swap partition out of the free space on the live usb:
   1. Add partition
      - `sudo fdisk --type=dos --wipe=never /dev/sda`
      - Create new partition: n, p
      - Set type of new partition to swap: t, 82
   2. Make swap + enable it:
      ```console
      mkswap /dev/sda3
      swapon /dev/sda3
      ```
   3. Remount the tmpfs to give yourself a large nix store:
      ```console
      mount -o remount,size=64G,noatime /nix/.rw-store
      ```
6. Set password for your user:
   ```console
   sudo mkdir /mnt/root
   sudo mount -t zfs zroot/root /mnt/root
   sudo mount -t zfs zroot/root/nix /mnt/root/nix
   sudo mount -t zfs zroot/root/home /mnt/root/home

   sudo nixos-enter --root /mnt/root --command 'passwd jfly'
   ```

   TODO: ask upstream if it would be OK to add a hook for this to `disko-install`?
7. Reboot `sudo reboot`
   TODO: that didn't work (got wedged shutting down). do we need to unmount filesystems first?

Oops! Finally got the install to happen, and turns out I never set a password for my user :head-desk:

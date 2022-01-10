Our secondary NAS running on a Raspberry PI 4.

## Bootstrapping Raspberry PI 4 ##

The goal here is to get the RPI running Nix, connected to the network with the
right hostname, and with ssh enabled and the ability to ssh as root.
Unfortunately, this is a pretty manual process because I don't know how to
cross compile a nice sdcard image. From
https://nixos.wiki/wiki/NixOS_on_ARM#Build_your_own_image:

> Note that this requires a machine with aarch64. You can however also build it
> from your laptop using an aarch64 remote builder as described in Distributed
> build or ask for access on the community aarch64 builder.

TODO: try out https://rbf.dev/blog/2020/05/custom-nixos-build-for-raspberry-pis/

(These instructions adapted from https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4)

Now set up a USB drive, and boot from it with ethernet connected.

    $ wget https://hydra.nixos.org/build/163396845/download/1/nixos-sd-image-21.11.335109.00acdb2aa81-aarch64-linux.img.zst
    $ nix-shell -p zstd --run "unzstd *.img.zst"
    $ sudo dd bs=4M if=nixos-sd-image-21.11.335109.00acdb2aa81-aarch64-linux.img of=USB_DEVICE_HERE conv=fsync oflag=direct status=progress

Now on the freshly booted machine.

    $ mkdir ~/.ssh
    $ curl https://github.com/jfly.keys > ~/.ssh/authorized_keys

At this point, you can continue from a laptop by doing `ssh nixos@nixos`.

    # Manually copy fflam/configuration.nix to the new machine. Be prepared to
    # tweak it to get the next command to work.
    $ sudo nixos-install --root /
    $ nixos-generate-config --root /mnt
    $ nixos-install
    $ reboot

Now the machine is bootstrapped and ready for regular deployment (see top level
README for instructions).

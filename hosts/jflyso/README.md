# jflyso

Pronounced like ISO =)

This produces a livecd environment that I can ssh to without having to touch anything.

# Build

```shell
nix build .#nixosConfigurations.jflyso.config.system.build.isoImage
```

To test that image you just built:

```shell
nix shell nixpkgs#qemu --command qemu-system-x86_64 -enable-kvm -m 256 -cdrom result/iso/nixos-*.iso
```

To write it to a usb (you probably need `sudo` for this):

```shell
cp result/iso/nixos-*.iso /dev/[DEVICE]
```

Plug it into a machine, boot, and have fun hacking!

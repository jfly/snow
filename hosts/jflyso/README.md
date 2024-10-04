# jflyso

Pronounced like ISO =)

This produces a livecd environment that I can ssh to without having to touch anything.

## Build

```shell
nix build .#jflyso-iso
```

## Burn and boot

To write it to a usb (you probably need `sudo` for this):

```shell
cp result/iso/nixos-*.iso /dev/[DEVICE]
```

Plug it into a machine, boot, and have fun hacking!

## No usb drive?

Try out netboot!

```shell
nix run .#jflyso-netboot
```

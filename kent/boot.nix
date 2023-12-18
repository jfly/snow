{ pkgs, ... }:

{
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      # Copied from nixos/modules/installer/sd-card/sd-image-raspberrypi.nix
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  # Workaround from https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
  # Without this, building the kernel fails with "modprobe: FATAL: Module sun4i-drm not found in directory ...".
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
}

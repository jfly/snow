{ config, lib, ... }:

{
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Keep only a finite number of boot configurations. This prevents /boot from
  # filling up.
  # https://nixos.wiki/wiki/Bootloader#Limiting_amount_of_entries_with_grub_or_systemd-boot
  boot.loader.systemd-boot.configurationLimit = 100;

  # Lol: https://discourse.nixos.org/t/whats-the-rationale-behind-not-detected-nix/5403
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/c13aba0e-7fc5-49f9-b862-d2e320dc8593";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/58EF-2CB2";
      fsType = "vfat";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

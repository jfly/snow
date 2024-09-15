{ lib, ... }:

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

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/5175cd9f-3a1b-479f-a9f6-e0331b714377";
      fsType = "ext4";
      # ssd tuning recommended by: https://nixos.wiki/wiki/Nixos-generate-config
      options = [ "noatime" "nodiratime" "discard" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/574B-D90F";
      fsType = "vfat";
    };

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = true;
}

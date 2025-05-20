{ flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.initrd-ssh-tor
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "locked-vm";
  clan.core.deployment.requireExplicitUpdate = true;

  disko.devices.disk.main.device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";
}

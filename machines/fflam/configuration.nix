{ flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.monitoring
    flake.nixosModules.initrd-ssh-tor
    ./hardware-configuration.nix
    ./disko.nix
    ./nas.nix
  ];

  networking.hostName = "fflam";

  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-TEAM_TM8FP6256G_TPBF2402010030504424";
}

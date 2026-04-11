{ flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.monitoring
    ./hardware-configuration.nix
    ./disko.nix
    ./nas.nix
    ./zrepl.nix
  ];

  networking.hostName = "fflam";

  # We don't back up any data from this machine. It *is* our backups.
  snow.backup.enable = false;

  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-TEAM_TM8FP6256G_TPBF2402010030504424";
}

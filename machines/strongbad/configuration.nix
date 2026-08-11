{ flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./cosmic.nix
    ./disko.nix
    ./users.nix
    ./flatpak.nix
  ];

  ### CHANGEME ##
  networking.hostName = "strongbad";

  # This machine is not online all the time.
  clan.core.deployment.requireExplicitUpdate = true;
  snow.monitoring.alertIfDown = false;

  # We don't back up any data from this machine.
  snow.backup.enable = false;

  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-eui.002538b521b24ddf";
}

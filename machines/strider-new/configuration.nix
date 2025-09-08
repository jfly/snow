{ inputs, flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    inputs.bpi-r4.nixosModules.default
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "strider-new";
  clan.core.deployment.requireExplicitUpdate = true; # TODO: remove
  snow.monitoring.alertIfDown = false; # TODO: remove

  disko.devices.disk.main.device = "/dev/disk/by-id/mmc-8GTF4R_0xef22ba96";
}

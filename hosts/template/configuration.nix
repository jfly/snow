{ flake, ... }:

{
  system.stateVersion = "24.11";

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  ### CHANGEME ##
  networking.hostName = "template";
  disko.devices.disk.main.device = "/dev/nvme0n1";

  services.getty.helpLine = ''
    This is a dead simple example of a fleet member. It's used as a template
    for creating new members of the fleet.
  '';
}

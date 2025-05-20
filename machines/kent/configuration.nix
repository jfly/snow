{ flake, config, ... }:

{
  networking.hostName = "kent";
  networking.domain = "sc";
  clan.core.networking.targetHost = "jfly@kent.sc.jflei.com";

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./disko-config.nix
    ./gpu.nix
    flake.nixosModules.xmonad-basic
    flake.nixosModules.kodi-colusita
    ./printer.nix
    ./dyndns.nix
  ];

  services.openssh.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.kodi-colusita = {
    enable = true;
    startOnBoot = true;
    moonlight.enable = false;
  };

  # Give the default user sudo permissions. Sometimes it's nice to be able to
  # debug things with a keyboard rather than ssh-ing to the box.
  users.users.${config.services.kodi-colusita.user}.extraGroups = [ "wheel" ];
}

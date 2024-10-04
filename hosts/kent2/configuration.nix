{ flake, ... }:

{
  networking.hostName = "kent2";
  system.stateVersion = "24.11";

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./disko-config.nix
    flake.nixosModules.xmonad-basic
    flake.nixosModules.kodi-colusita
  ];

  services.openssh.enable = true;

  services.kodi-colusita = {
    enable = true;
    startOnBoot = true;
  };
}

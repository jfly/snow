{ flake, ... }:

let
  identities = flake.lib.identities;
  username = "kent2";
in
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

  users = {
    mutableUsers = false;
    users.${username} = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        identities.jfly
      ];
    };
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };

  services.kodi-colusita = {
    enable = true;
    startOnBoot = true;
  };
}

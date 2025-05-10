{ flake, ... }:

let
  identities = flake.lib.identities;
in
{
  boot.loader.grub.enable = true;
  services.openssh.enable = true;

  networking.hostName = "fflam";
  clan.core.networking = {
    buildHost = "localhost";
    targetHost = "jfly@fflam";
  };

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./network.nix
    ./disko.nix
    ./mail.nix
  ];

  # Enable deployments by non-root user.
  nix.settings.trusted-users = [ "@wheel" ];
  security.sudo.wheelNeedsPassword = false;

  users.users.fflam = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ identities.jfly ];
  };
}

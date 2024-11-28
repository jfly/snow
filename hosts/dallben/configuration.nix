{ flake, config, ... }:

let
  identities = flake.lib.identities;
in
{
  networking.hostName = "dallben";
  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "21.11";
  services.openssh.enable = true;
  #<<< TODO: remove >>>

  # Allow ssh access as root user.
  users.users.root = {
    openssh.authorizedKeys.keys = [ identities.jfly ];
  };

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./boot.nix
    ./gpu.nix
    ./bluetooth.nix
    flake.nixosModules.xmonad-basic
    flake.nixosModules.kodi-colusita
  ];

  services.kodi-colusita = {
    enable = true;
    startOnBoot = true;
  };

  # Give the default user sudo permissions. Sometimes it's nice to be able to
  # debug things with a keyboard rather than ssh-ing to the box.
  users.users.${config.services.kodi-colusita.user}.extraGroups = [ "wheel" ];
}

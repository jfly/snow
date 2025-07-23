{ flake, config, ... }:

{
  networking.hostName = "dallben";
  time.timeZone = "America/Los_Angeles";
  services.openssh.enable = true;

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
    moonlight.enable = true;
  };

  # This device regularly goes to sleep.
  snow.monitoring.alertIfDown = false;

  # Give the default user `sudo` permissions. Sometimes it's nice to be able to
  # debug things with a keyboard rather than ssh-ing to the box.
  users.users.${config.services.kodi-colusita.user}.extraGroups = [ "wheel" ];
}

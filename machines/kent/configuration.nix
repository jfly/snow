{ flake, config, ... }:

{
  networking.hostName = "kent";
  snow.network.lan = {
    tld = "sc";
    # Keep this in sync with <http://primary-router.sc/routers/strider/files/etc/config/dhcp>.
    ip = "192.168.1.125";
  };

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./disko-config.nix
    ./gpu.nix
    flake.nixosModules.xmonad-basic
    flake.nixosModules.kodi-colusita
    ./printer.nix
    ./dyndns.nix
    ./immichframe.nix
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

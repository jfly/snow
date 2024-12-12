{ flake, config, ... }:

{
  networking.hostName = "kent";
  system.stateVersion = "24.11";

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
  };

  # Give the default user sudo permissions. Sometimes it's nice to be able to
  # debug things with a keyboard rather than ssh-ing to the box.
  users.users.${config.services.kodi-colusita.user}.extraGroups = [ "wheel" ];

  age.rooter.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLwEMWt15EGJ0Cpqu0VjoIyIOS3/qIcPhwRs8QgqG+r";
}

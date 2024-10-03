{ flake, ... }:

{
  networking.hostName = "kent";
  system.stateVersion = "22.11";

  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./hardware-configuration-custom.nix
    ./boot.nix
    ./users.nix
    ./printer.nix
    ./dyndns.nix
    flake.nixosModules.xmonad-basic
    ./kodi.nix

    ./nas.nix
    # TODO: get off site backups working again!
    # ./snow-backup.nix
  ];

  services.openssh.enable = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "kent";
  };

  age.rooter.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLwEMWt15EGJ0Cpqu0VjoIyIOS3/qIcPhwRs8QgqG+r";
}

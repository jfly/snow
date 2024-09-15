{ inputs, ... }:

{
  system.stateVersion = "22.11";
  networking.hostName = "kent";

  imports = [
    ./hardware-configuration.nix
    ./hardware-configuration-custom.nix
    ./boot.nix
    ./users.nix
    ./printer.nix
    ./dyndns.nix
    ./desktop
    ./kodi.nix

    ./nas.nix
    # TODO: get off site backups working again!
    # ./snow-backup.nix
    inputs.agenix.nixosModules.default
    inputs.agenix-rooter.nixosModules.default
  ];

  age.rooter.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLwEMWt15EGJ0Cpqu0VjoIyIOS3/qIcPhwRs8QgqG+r";
}

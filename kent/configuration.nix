{ agenix, agenix-rooter }:
{ config, lib, pkgs, ... }:

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

    #<<< ./nas.nix
    #<<< ./snow-backup.nix
    agenix.nixosModules.default
    agenix-rooter.nixosModules.default
  ];

  age.rooter = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLwEMWt15EGJ0Cpqu0VjoIyIOS3/qIcPhwRs8QgqG+r";
    generatedForHostDir = ../agenix-rooter-reencrypted-secrets;
  };
}

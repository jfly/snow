{ agenix, agenix-rooter, nixos-hardware }:
{ config, lib, pkgs, ... }:

{
  system.stateVersion = "23.11";

  imports = [
    ./boot.nix
    ./network.nix
    ./users.nix
    ./printer.nix
    agenix.nixosModules.default
    agenix-rooter.nixosModules.default
    nixos-hardware.nixosModules.raspberry-pi-4
  ];

  age.rooter = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDXMILluw9CwTHm/wTjL4xcJt6O71Dd/PSkfusGRY5T1";
    generatedForHostDir = ../agenix-rooter-reencrypted-secrets;
  };
}

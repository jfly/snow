{ agenix, agenix-rooter, nixos-hardware }:
{ config, lib, pkgs, ... }:

{
  system.stateVersion = "23.11";
  networking.hostName = "kent";

  imports = [
    ./boot.nix
    ./users.nix
    ./printer.nix
    ./dyndns.nix
    ./desktop
    ./cec.nix
    ./audio.nix
    ./kodi.nix
    agenix.nixosModules.default
    agenix-rooter.nixosModules.default
    nixos-hardware.nixosModules.raspberry-pi-4
  ];

  # From https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4#Configuration
  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
  };

  age.rooter = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDXMILluw9CwTHm/wTjL4xcJt6O71Dd/PSkfusGRY5T1";
    generatedForHostDir = ../agenix-rooter-reencrypted-secrets;
  };
}

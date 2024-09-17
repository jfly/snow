{ ... }:

rec {
  nixosModules.agenixRooter = import ./modules/agenix-rooter.nix;
  nixosModules.default = nixosModules.agenixRooter;
  defineApps = { flake, pkgs, flakeRoot, ... }: import ./apps { inherit flake pkgs flakeRoot; };
}

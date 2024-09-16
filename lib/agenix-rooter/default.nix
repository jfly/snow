{ ... }:

rec {
  nixosModules.agenixRooter = import ./modules/agenix-rooter.nix;
  nixosModules.default = nixosModules.agenixRooter;
  perSystem = { flake, pkgs, flakeRoot, ... }: {
    apps = import ./apps { inherit flake pkgs flakeRoot; };
  };
}

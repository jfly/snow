{ nixpkgs }:

rec {
  nixosModules.agenixRooter = import ./modules/agenix-rooter.nix nixpkgs;
  nixosModules.default = nixosModules.agenixRooter;
  defineApps = import ./apps;
}

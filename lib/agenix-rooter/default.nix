rec {
  nixosModules.agenixRooter = import ./modules/agenix-rooter.nix;
  nixosModules.default = nixosModules.agenixRooter;
  defineApps = import ./apps;
}

{
  description = "snow";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "mach-nix/3.5.0";
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = import ./overlays;
        };
      in
      {
        devShells.default = pkgs.callPackage ./shell.nix {
          mach-nix = mach-nix.lib."${system}";
        };
      }
    );
}

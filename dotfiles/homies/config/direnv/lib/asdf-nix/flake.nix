{
  description = "asdf, but with nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "mach-nix/3.5.0";
    mach-nix.inputs.pypi-deps-db.url = "github:DavHau/pypi-deps-db";
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        rec {
          lib = import ./default.nix {
            inherit pkgs;
            mach-nix = mach-nix.lib.${system};
          };
        }
      );
}

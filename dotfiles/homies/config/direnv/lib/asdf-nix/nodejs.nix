{ pkgs, callPackage }:

let
  buildNodejs = callPackage (<nixpkgs> + "/pkgs/development/web/nodejs/nodejs.nix") {
    python = pkgs.python3;
  };
  shaByVersion = {
    "14.18.2" = "sha256-Poqc4Q+LzTYo623QSffwPIS6khm+b5dD4iIRVLnMaAs=";
  };
in
version: buildNodejs {
  enableNpm = true;
  version = version;
  sha256 = shaByVersion.${version};
}

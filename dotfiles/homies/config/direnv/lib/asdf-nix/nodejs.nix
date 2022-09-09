{ pkgs, callPackage }:

let
  shaByVersion = {
    "14.18.2" = "sha256-Poqc4Q+LzTYo623QSffwPIS6khm+b5dD4iIRVLnMaAs=";
  };
in
version: pkgs.nodejs.overrideAttrs (oldAttrs: {
  inherit version;
  src = pkgs.fetchurl {
    url = "https://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
    sha256 = shaByVersion.${version};
  };
  patches = [ ];
})

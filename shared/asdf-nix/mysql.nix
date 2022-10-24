{ pkgs }:
let
  versions = {
    # This is a lie: it's not actually 8.0.28.
    "8.0.28" = pkgs.mysql80;
    # This doesn't work right now: compilation fails complaining that we have
    # too new a version of boost available :p
    # "8.0.28" = pkgs.mysql80.overrideAttrs (oldAttrs: rec {
    #   version = "8.0.28";
    #   src = pkgs.fetchurl {
    #     url = "https://dev.mysql.com/get/Downloads/MySQL-8.0/${oldAttrs.pname}-${version}.tar.gz";
    #     sha256 = "sha256-2Gk2nrbeTyuy2407Mbe3OWjjVuX/xDVPS5ZlirHkiyI=";
    #   };
    # });
  };
in
version: versions.${version}

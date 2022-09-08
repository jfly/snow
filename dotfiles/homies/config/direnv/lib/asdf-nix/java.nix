{ pkgs }:
let
  versions = {
    "openjdk-17" = pkgs.openjdk17;
  };
in
version: versions.${version}

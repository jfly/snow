{ pkgs }:
let
  versions = {
    # This is a lie.
    "0.8.0" = pkgs.shellcheck;
  };
in
version: versions.${version}

{ pkgs }:
let
  versions = {
    # This is a lie.
    "3.4.3" = pkgs.shfmt;
  };
in
version: versions.${version}

{ pkgs }:
let
  versions = {
    # Note: this is probably a lie. Sorry, I'm not up for figuring out how to
    # specify exact patch versions here right now.
    "adoptopenjdk-11.0.15+10" = pkgs.openjdk11;
    "openjdk-17" = pkgs.openjdk17;
  };
in
version: versions.${version}

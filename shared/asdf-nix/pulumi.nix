{ pkgs, fetchFromGitHub, coreutils, lib, stdenv, runCommand, makeWrapper, fetchurl }:
let
  versions = {
    "3.86.0" = pkgs.pulumi-bin.overrideAttrs (oldAttrs:
      let
        data = import ./pulumi-data.nix { };
      in
      {
        version = data.version;
        srcs = map (x: fetchurl x) data.pulumiPkgs.${stdenv.hostPlatform.system};
      });
  };
in
version: versions.${version}

{ pkgs, fetchFromGitHub, coreutils, lib, stdenv, runCommand, makeWrapper, fetchurl }:
let
  # To generate pulumi-data for a specific version of pulumi:
  #  $ cd ~/src/github.com/NixOS/nixpkgs/pkgs/tools/admin/pulumi-bin/
  #  $ GITHUB_TOKEN=$(gh auth token) ./update.sh [VERSION]
  #  $ cp data.nix /home/jeremy/src/github.com/jfly/snow/shared/asdf-nix/pulumi/pulumi-data-[VERSION].nix
  versions = {
    "3.86.0" = pkgs.pulumi-bin.overrideAttrs (oldAttrs:
      let
        data = import ./pulumi-data-3_86_0.nix { };
      in
      {
        version = data.version;
        srcs = map (x: fetchurl x) data.pulumiPkgs.${stdenv.hostPlatform.system};
      });
    "3.104.2" = pkgs.pulumi-bin.overrideAttrs (oldAttrs:
      let
        data = import ./pulumi-data-3_104_2.nix { };
      in
      {
        version = data.version;
        srcs = map (x: fetchurl x) data.pulumiPkgs.${stdenv.hostPlatform.system};
      });
    "3.128.0" = pkgs.pulumi-bin.overrideAttrs (oldAttrs:
      let
        data = import ./pulumi-data-3_128_0.nix { };
      in
      {
        version = data.version;
        srcs = map (x: fetchurl x) data.pulumiPkgs.${stdenv.hostPlatform.system};
      });
  };
in
version: versions.${version}

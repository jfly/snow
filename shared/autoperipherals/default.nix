{ pkgs ? import <nixpkgs> { }, with-alacritty }:

pkgs.python3Packages.callPackage ./package.nix { inherit with-alacritty; }

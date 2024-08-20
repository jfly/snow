{ pkgs ? import <nixpkgs> { } }:

pkgs.python3Packages.callPackage ./py-package.nix { }

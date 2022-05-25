{ pkgs ? ((import ../sources.nix).nixpkgs {}) }:

pkgs.callPackage ./derivation.nix {}

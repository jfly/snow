{ pkgs ? import <nixpkgs> {} }:
pkgs.callPackage ./receiver.nix {}

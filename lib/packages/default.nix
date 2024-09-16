{ inputs, ... }:

{ pkgs, ... }@systemArgs:

let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs.lib)
    filesystem
    ;
in
filesystem.packagesFromDirectoryRecursive {
  callPackage = pkgs.newScope systemArgs;
  directory = ../../packages;
}

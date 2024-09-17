{
  self,
  inputs,
  lib,
  ...
}:

{
  perSystem =
    {
      self',
      inputs',
      system,
      pkgs,
      config,
      ...
    }:
    let
      pkgArgs = {
        flake = self;
        flake' = self' // {
          inherit config;
        };
        inherit inputs inputs' system;
      };
    in
    {
      packages = lib.filesystem.packagesFromDirectoryRecursive {
        callPackage = pkgs.newScope pkgArgs;
        directory = ../packages;
      };
    };
}

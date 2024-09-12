{ lib, callPackage }:

lib.filesystem.packagesFromDirectoryRecursive {
  inherit callPackage;
  directory = ./.;
}

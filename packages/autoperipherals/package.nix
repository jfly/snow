{
  flake',
  pkgs,
}:

pkgs.python3Packages.callPackage ./py-package.nix { inherit flake'; }

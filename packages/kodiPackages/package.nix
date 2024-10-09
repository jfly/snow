{ pkgs }:

let
  kodiPackages = pkgs.callPackage ./default.nix { };
in

# This is a hack just to make `nix flake check` happy, because it
# (understandably) wants all packages to be... a package.
# Perhaps it would be cleaner to create a non-standard `packageSets` output and
# stash this under that?
pkgs.runCommand "kodiPackages" { passthru = kodiPackages; } ''
  echo 'ignore, this is a package set' > $out
''

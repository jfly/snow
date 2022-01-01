{ newScope, pkgs }:

let self = rec {
  # Pull some all of pkgs.kodiPackages into scope + cleverly make the new kodi
  # packages we're defining available as well so they can depend on each other.
  callPackage = newScope (pkgs.kodiPackages // self);

  # TODO: these should all get upstreamed to
  #       nixpkgs/pkgs/top-level/kodi-packages.nix
  arrow = callPackage ./arrow {};
  bottle = callPackage ./bottle {};
  pyxbmct = callPackage ./pyxbmct {};
  tubecast = callPackage ./tubecast {};
  tubed-api = callPackage ./tubed-api {};
  tubed = callPackage ./tubed {};

  # Mine! No intention of upstreaming these.
  autoreceiver = callPackage ./autoreceiver {};
  media = callPackage ./media {};
  parsec = callPackage ./parsec {};
}; in self

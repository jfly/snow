{ newScope, pkgs, myParsec }:

let
  self = rec {
    # Pull some all of pkgs.kodiPackages into scope + cleverly make the new kodi
    # packages we're defining available as well so they can depend on each other.
    callPackage = newScope (pkgs.kodiPackages // self);

    # TODO: these should all get upstreamed to
    #       nixpkgs/pkgs/top-level/kodi-packages.nix
    bottle = callPackage ./bottle { };
    tubecast = callPackage ./tubecast { };

    # Mine! No intention of upstreaming these.
    autoreceiver = callPackage ./autoreceiver { };
    parsec = callPackage ./parsec {
      inherit myParsec;
    };
  };
in
self

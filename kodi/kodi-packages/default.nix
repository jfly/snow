{ newScope, pkgs }:

let self = rec {
  callPackage = newScope self;
  # Pull some misc dependencies into scope so callPackage can pass them to the
  # relevant packages if they want them.
  # TODO: find a better way of doing this
  buildKodiAddon = pkgs.kodiPackages.buildKodiAddon;
  addonUpdateScript = pkgs.kodiPackages.addonUpdateScript;
  certifi = pkgs.kodiPackages.certifi;
  chardet = pkgs.kodiPackages.chardet;
  dateutil = pkgs.kodiPackages.dateutil;
  idna = pkgs.kodiPackages.idna;
  inputstream-adaptive = pkgs.kodiPackages.inputstream-adaptive;
  kodi-six = pkgs.kodiPackages.kodi-six;
  requests = pkgs.kodiPackages.requests;
  six = pkgs.kodiPackages.six;
  urllib3 = pkgs.kodiPackages.urllib3;
  youtube = pkgs.kodiPackages.youtube;

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

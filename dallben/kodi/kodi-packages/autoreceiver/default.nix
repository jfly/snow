{ pkgs }:

let
  receiver = pkgs.callPackage ../../receiver { };
in
pkgs.kodiPackages.toKodiAddon (pkgs.stdenv.mkDerivation {
  name = "kodi-autoreceiver";
  namespace = "script.autoreceiver";

  src = ./src;

  prePatch = ''
    substituteInPlace share/kodi/addons/script.autoreceiver/service.py --replace "@receiver@" "${receiver}"
  '';

  installPhase = "cp -r . $out";
})

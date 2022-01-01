{ pkgs }:

pkgs.kodiPackages.toKodiAddon (pkgs.stdenv.mkDerivation {
  name = "kodi-parsec";
  namespace = "script.parsec";

  src = ./src;

  installPhase = "cp -r . $out";
})

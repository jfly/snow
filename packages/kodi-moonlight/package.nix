{ stdenv, kodiPackages }:

kodiPackages.toKodiAddon (
  stdenv.mkDerivation {
    name = "kodi-moonlight";
    namespace = "script.moonlight";

    src = ./src;

    installPhase = "cp -r . $out";
  }
)

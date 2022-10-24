{ pkgs, config }:

pkgs.kodiPackages.toKodiAddon (pkgs.stdenv.mkDerivation {
  name = "media";
  src = ./src;

  installPhase = "cp -r . $out";
})

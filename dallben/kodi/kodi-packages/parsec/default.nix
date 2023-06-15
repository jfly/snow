{ pkgs, myParsec }:

pkgs.kodiPackages.toKodiAddon (pkgs.stdenv.mkDerivation {
  name = "kodi-parsec";
  namespace = "script.parsec";

  src = ./src;

  installPhase = ''
    cp -r . $out
    substituteInPlace $out/share/kodi/addons/script.parsec/addon.py \
      --replace "@parsec@" "${myParsec}"
  '';
})

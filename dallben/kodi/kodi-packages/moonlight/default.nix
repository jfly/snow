{ pkgs }:

pkgs.kodiPackages.toKodiAddon (pkgs.stdenv.mkDerivation {
  name = "kodi-moonlight";
  namespace = "script.moonlight";

  src = ./src;

  installPhase = ''
    cp -r . $out
    substituteInPlace $out/share/kodi/addons/script.moonlight/addon.py \
      --replace "@moonlight@" "${pkgs.moonlight-qt}"
  '';
})

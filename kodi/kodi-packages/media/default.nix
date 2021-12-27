{ pkgs }:

let secrets = (import ../../../secrets.nix);
in
pkgs.kodiPackages.toKodiAddon (pkgs.stdenv.mkDerivation {
  name = "media";

  src = ./src;

  installPhase = ''
    cp -r . $out
    substituteInPlace $out/share/kodi/system/advancedsettings.xml \
      --replace "@mysql_pass@" "${secrets.kodi.mysql.password}"
  '';
})

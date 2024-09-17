{ pkgs, deviceName }:

pkgs.kodiPackages.toKodiAddon (pkgs.stdenv.mkDerivation {
  name = "media";
  src = ./src;

  postBuild = ''
    substituteInPlace share/kodi/system/advancedsettings.xml \
      --replace-fail "@devicename@" ${deviceName}
  '';
  installPhase = "cp -r . $out";
})

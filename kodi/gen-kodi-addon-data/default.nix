{pkgs}:

pkgs.stdenv.mkDerivation {
  name = "gen-kodi-addon-data";
  src = ./src;
  installPhase = "cp -r . $out";
}

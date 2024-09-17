{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "gen-kodi-addon-data";
  src = ./src;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildPhase = ''
    cp -r . $out
    wrapProgram $out/gen-kodi-addon-data.sh \
      --prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.rsync
        ]
      }
  '';
}

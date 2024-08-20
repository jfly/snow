{ pkgs ? import <nixpkgs> { } }:

pkgs.symlinkJoin {
  name = "mycli";
  paths = [ pkgs.mycli ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/mycli \
      --add-flags "--myclirc ${./myclirc}"
  '';
}

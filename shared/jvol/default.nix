{ pkgs ? (import ../../sources.nix).nixos-unstable { } }:

let
  jvol = with pkgs.python3Packages; buildPythonApplication {
    pname = "jvol";
    version = "1.0";
    format = "pyproject";

    src = ./.;
  };
in
pkgs.symlinkJoin {
  name = "jvol";
  paths = [ jvol ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/jvol \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.pamixer ]}
  '';
}

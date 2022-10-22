{ pkgs ? (import ../../sources.nix).nixos-unstable { } }:

let
  jbright = with pkgs.python3Packages; buildPythonApplication {
    pname = "jbright";
    version = "1.0";
    format = "pyproject";

    nativeBuildInputs = [ setuptools ];
    src = ./.;
  };
in
pkgs.symlinkJoin {
  name = "jbright";
  paths = [ jbright ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/jbright \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.brightnessctl
        pkgs.libnotify
      ]}
  '';
}

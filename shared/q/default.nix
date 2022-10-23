{ pkgs ? import <nixpkgs> { } }:

pkgs.writeShellApplication {
  name = "q";
  runtimeInputs = [ pkgs.sox ];
  text = ''
    export WAV_FOLDER=${./wav}
    ${builtins.readFile ./q}
  '';
}

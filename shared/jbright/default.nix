{ pkgs ? (import ../../sources.nix).nixos-unstable { }
, lib ? pkgs.lib
, volnoti ? pkgs.callPackage (import ../volnoti) { }
}:

let jbright = with pkgs.python3Packages; buildPythonApplication {
  pname = "jbright";
  version = "1.0";
  format = "pyproject";

  src = ./.;
};
in
pkgs.symlinkJoin {
  name = "jbright";
  paths = [ jbright ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/jbright \
      --prefix PATH : ${lib.makeBinPath [ pkgs.brightnessctl ]}
  '';
}

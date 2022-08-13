{ pkgs ? (import ../../sources.nix).nixos-unstable { }
, volnoti ? pkgs.callPackage (import ../volnoti) { }
}:

with pkgs.python3Packages; buildPythonApplication {
  pname = "jvol";
  version = "1.0";
  format = "pyproject";

  src = ./.;
}

{ pkgs ? (import ../../sources.nix).nixos-unstable { } }:

with pkgs.python3Packages; buildPythonApplication {
  pname = "jgit";
  version = "1.0";
  format = "pyproject";

  src = ./.;
  nativeBuildInputs = [ setuptools ];
  checkInputs = [ pytest ];
  checkPhase = "pytest";
}

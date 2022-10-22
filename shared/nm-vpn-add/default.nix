{ pkgs ? import <nixpkgs> { } }:

with pkgs.python3Packages; buildPythonApplication {
  pname = "nm-vpn-add";
  version = "1.0";
  format = "pyproject";

  nativeBuildInputs = [ setuptools ];
  src = ./.;
}

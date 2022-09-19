{ pkgs ? import <nixpkgs> { } }:

pkgs.python3Packages.buildPythonApplication {
  pname = "nm-vpn-add";
  version = "1.0";
  format = "pyproject";

  src = ./.;
}

{ pkgs ? import <nixpkgs> { } }:

with pkgs.python3Packages; buildPythonApplication {
  pname = "polybar-openvpn3";
  version = "1.0";
  format = "pyproject";

  nativeBuildInputs = [ setuptools ];
  src = ./.;

  propagatedBuildInputs = pkgs.openvpn3.pythonPath ++ [ pkgs.openvpn3 ];
}

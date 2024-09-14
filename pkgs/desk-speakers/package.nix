{ pkgs }:

with pkgs.python3Packages; buildPythonApplication {
  pname = "desk-speakers";
  version = "1.0";
  format = "pyproject";

  src = ./.;
  nativeBuildInputs = [ setuptools ];
  propagatedBuildInputs = [
    pulsectl
    dbus-python
  ];
}

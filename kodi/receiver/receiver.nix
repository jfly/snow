{ lib, python3Packages }:

with python3Packages;
buildPythonApplication {
  pname = "receiver";
  version = "1.0";

  propagatedBuildInputs = [ rxv ];

  src = ./.;
}

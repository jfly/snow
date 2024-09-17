{ pkgs }:

with pkgs.python3Packages;
buildPythonApplication {
  pname = "jgit";
  version = "1.0";
  format = "pyproject";

  src = ./.;
  nativeBuildInputs = [ setuptools ];
  nativeCheckInputs = [ pytest ];
  checkPhase = "pytest";
}

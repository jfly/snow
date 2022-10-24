{ lib, python3Packages }:
with python3Packages; buildPythonApplication {
  pname = "with-alacritty";
  version = "1.0";

  checkInputs = [ pytestCheckHook ];
  pytestFlagsArray = [ "--ignore=result" ];

  propagatedBuildInputs = [
    mergedeep
    psutil
    pyxdg
  ];

  nativeBuildInputs = [
    black
    pytest
  ];

  src = ./.;
}

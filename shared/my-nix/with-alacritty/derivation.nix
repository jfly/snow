{ black
, buildPythonApplication
, mergedeep
, psutil
, pytestCheckHook
, pyxdg
, tomli-w
}:
buildPythonApplication {
  pname = "with-alacritty";
  version = "1.0";

  checkInputs = [ pytestCheckHook ];
  pytestFlagsArray = [ "--ignore=result" ];

  propagatedBuildInputs = [
    mergedeep
    psutil
    pyxdg
    tomli-w
  ];

  nativeBuildInputs = [
    black
  ];

  src = ./.;
}

{ lib, buildKodiAddon, fetchFromGitHub, six, kodi-six }:

buildKodiAddon rec {
  pname = "pyxbmct";
  namespace = "script.module.pyxbmct";
  version = "1.3.1+matrix.1";

  src = fetchFromGitHub {
    owner = "romanvm";
    repo = "script.module.pyxbmct";
    rev = version;
    sha256 = "1iagx89khk98yh22l4rv6hzd3ykj98i2d39w7j11hdba0gfqi9sg";
  };

  propagatedBuildInputs = [
    six
    kodi-six
  ];

  meta = with lib; {
    homepage = "http://romanvm.github.io/PyXBMCt";
    description = "PyXBMCt is a mini-framework for simple XBMC addon UI buliding. It is similar to PyQt and provides parent windows, a number of UI controls (widgets) and a grid layout manager to place controls.";
    license = licenses.gpl3Only;
    maintainers = teams.kodi.members;
  };
}

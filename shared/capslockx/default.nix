{ lib, python3Packages, libX11 }:

with python3Packages;
buildPythonApplication {
  pname = "capslockx";
  version = "1.0";

  src = ./.;
  postPatch = ''
    substituteInPlace capslockx.py \
      --replace libX11.so.6 ${libX11}/lib/libX11.so.6
  '';
}

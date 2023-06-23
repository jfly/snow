{ fetchFromGitHub
, lib
, pkgs
, python39
, umockdev
, writeScript
}:

let
  python3 = python39; # TODO: revert to plain old python3 once https://github.com/NixOS/nixpkgs/issues/238990 is fixed.
  launch-sendto_silhouette = writeScript "sendto_silhouette.sh" ''
    cd $(dirname $0)
    ./sendto_silhouette.py "$@"
  '';
  launch-silhouette_multi = writeScript "silhouette_multi.sh" ''
    cd $(dirname $0)
    ./silhouette_multi.py "$@"
  '';
in
python3.pkgs.buildPythonApplication rec {
  pname = "inkscape-silhouette";
  version = "1.28.pre+unstable=2023-06-03"; # Note: there has been lot of as-yet-not-released development since 1.27 was released: https://github.com/fablabnbg/inkscape-silhouette/releases/tag/v1.27

  src = fetchFromGitHub {
    owner = "fablabnbg";
    repo = pname;
    rev = "a1941b6f740466a20dfa116415dd599b1e496302";
    sha256 = "sha256-CLmSHIhaqtSzPXB1HgHPG+fRW7ktcN3Y3IEWuCVLarw=";
  };

  patches = [
    ./interpreter.patch
  ];

  propagatedBuildInputs = [
    python3.pkgs.pyusb
    python3.pkgs.lxml
    python3.pkgs.inkex
    python3.pkgs.matplotlib
  ];

  nativeCheckInputs = [
    python3.pkgs.pytestCheckHook
    umockdev
  ];

  pytestFlagsArray = [
    "test"
  ];

  format = "setuptools";

  doCheck = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/inkscape/extensions
    make install DESTDIR=$out PREFIX=
    # Unmark read_dump.py as executable so wrapPythonProgramsIn won't turn it into a shell script (thereby making it impossible to import as a Python module).
    chmod -x $out/share/inkscape/extensions/silhouette/read_dump.py
    cp ${launch-sendto_silhouette} $out/share/inkscape/extensions/sendto_silhouette.sh
    cp ${launch-silhouette_multi} $out/share/inkscape/extensions/silhouette_multi.sh

    runHook postInstall
  '';

  postFixup = ''
    wrapPythonProgramsIn "$out/share/inkscape/extensions/" "$out $pythonPath"
  '';

  meta = with lib; {
    homepage = "https://github.com/fablabnbg/inkscape-silhouette";
    description = "An extension to drive Silhouette vinyl cutters (e.g. Cameo, Portrait, Curio series) from within inkscape.";
    license = licenses.gpl2;
    platforms = platforms.all;
  };
}

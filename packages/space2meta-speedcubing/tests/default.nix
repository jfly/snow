{
  stdenv,
  python3,
  space2meta-speedcubing-untested,
  lndir,
}:

stdenv.mkDerivation {
  name = "space2meta-speedcubing";
  src = ./.;

  doCheck = true;
  nativeCheckInputs = with python3.pkgs; [
    pytestCheckHook
    pytest-xdist
    evdev
  ];

  checkInputs = [ space2meta-speedcubing-untested ];

  installPhase = ''
    mkdir $out
    ${lndir}/bin/lndir -silent ${space2meta-speedcubing-untested} $out
  '';
}

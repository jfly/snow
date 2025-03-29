{
  flake',
  pkgs,
  callPackage,
  buildPythonApplication,
  setuptools,
  pydantic,
  click,
  pyxdg,
  xlib,
  wireplumber,
  pipewire,
}:

let
  addToPath =
    (with pkgs; [
      xorg.xrandr
      killall
      libnotify
    ])
    ++ (with flake'.packages; [
      setbg
    ]);
  pyedid = callPackage ./pyedid.nix { };
in
buildPythonApplication {
  pname = "autoperipherals";
  version = "1.0";
  format = "pyproject";

  nativeBuildInputs = [
    setuptools
  ];
  propagatedBuildInputs = [
    click
    pydantic
    pyedid
    pyxdg
    xlib
    wireplumber # provides wpctl
    pipewire # provides pw-link
  ];
  src = ./.;

  preFixup = ''
    makeWrapperArgs+=("--prefix")
    makeWrapperArgs+=("PATH")
    makeWrapperArgs+=(":")
    makeWrapperArgs+=("${pkgs.lib.makeBinPath addToPath}")
  '';
}

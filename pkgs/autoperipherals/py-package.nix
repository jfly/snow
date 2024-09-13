{ inputs', flake', pkgs, callPackage, buildPythonApplication, setuptools, pydantic, click, pyxdg, xlib }:

let
  addToPath = (with pkgs; [
    xorg.xrandr
    killall
    libnotify
  ]) ++ (with flake'.packages; [
    setbg
  ]) ++ [
    inputs'.with-alacritty.packages.default
  ];
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
  ];
  src = ./.;

  preFixup = ''
    makeWrapperArgs+=("--prefix")
    makeWrapperArgs+=("PATH")
    makeWrapperArgs+=(":")
    makeWrapperArgs+=("${pkgs.lib.makeBinPath addToPath}")
  '';
}

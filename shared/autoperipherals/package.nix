{ pkgs, callPackage, buildPythonApplication, setuptools, pyxdg, xlib, with-alacritty }:

let
  setbg = pkgs.callPackage ../setbg { };
  addToPath = with pkgs; [
    xorg.xrandr
    killall
    libnotify
    with-alacritty
    setbg
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

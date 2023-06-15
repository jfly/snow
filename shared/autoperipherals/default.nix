{ pkgs ? import <nixpkgs> { } }:

let
  with-alacritty = pkgs.callPackage ../../shared/my-nix/with-alacritty { };
  capslockx = pkgs.callPackage ../capslockx { }; # TODO: unused?
  setbg = pkgs.callPackage ../setbg { };
in

with pkgs.python3Packages; buildPythonApplication rec {
  pname = "autoperipherals";
  version = "1.0";
  format = "pyproject";

  nativeBuildInputs = [
    setuptools
  ];
  addToPath = with pkgs; [
    xorg.xrandr
    killall
    libnotify
    with-alacritty
    setbg
  ];
  propagatedBuildInputs = [
    pyxdg
  ] ++ addToPath;
  src = ./.;

  preFixup = ''
    makeWrapperArgs+=("--prefix")
    makeWrapperArgs+=("PATH")
    makeWrapperArgs+=(":")
    makeWrapperArgs+=("${pkgs.lib.makeBinPath addToPath}")
  '';
}

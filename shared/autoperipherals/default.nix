{ pkgs ? import <nixpkgs> { } }:

let
  with-alacritty = pkgs.callPackage ../../shared/my-nix/with-alacritty { };
  capslockx = pkgs.callPackage ../capslockx { };
  setbg = pkgs.callPackage ../setbg { };
in
pkgs.writeShellApplication {
  name = "autoperipherals";
  text = builtins.readFile ./autoperipherals;
  runtimeInputs = with pkgs; [
    nettools # provides the `hostname` command
    xorg.xrandr
    procps # provides `pgrep`
    killall
    bc
    libnotify
    with-alacritty
    setbg
  ];
}

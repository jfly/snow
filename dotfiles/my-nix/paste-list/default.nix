{ pkgs ? import <nixpkgs> {} }:

let
  src = ./src;
  py-packages = (p: [p.xlib p.urwid]);
  python=pkgs.python3.withPackages py-packages;
in
  {
    deps = {
      inherit py-packages;
      inherit python;
    };
    paste-list=(
      pkgs.writeShellScriptBin "paste-list" ''
        ${python}/bin/python ${src}/paste-list.py "$@"
      ''
    );
  }

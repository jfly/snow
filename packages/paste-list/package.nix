{ pkgs }:

let
  src = ./src;
  py-packages = (p: [ p.xlib p.urwid ]);
  python = pkgs.python3.withPackages py-packages;
in
pkgs.writeShellScriptBin "paste-list" ''
  ${python}/bin/python ${src}/paste-list.py "$@"
''

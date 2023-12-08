{ pkgs }:

let
  space2meta-speedcubing-untested = pkgs.callPackage ./src { };
  space2meta-speedcubing-tested = pkgs.callPackage ./tests { inherit space2meta-speedcubing-untested; };
in
space2meta-speedcubing-tested

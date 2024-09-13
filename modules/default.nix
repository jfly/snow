{ inputs, ... }:

let
  inherit (inputs.nixpkgs.lib)
    filterAttrs
    mapAttrs
    ;
  moduleDirs = filterAttrs (_name: type: type == "directory") (builtins.readDir ./.);
in

mapAttrs (name: _type: import (./. + "/${name}")) moduleDirs

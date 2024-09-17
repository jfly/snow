{ lib, ... }:

let
  moduleDir = ../nixos-modules;
  moduleDirs = lib.filterAttrs (_name: type: type == "directory") (builtins.readDir moduleDir);
in

{
  flake.nixosModules = lib.mapAttrs (name: _type: import (moduleDir + "/${name}")) moduleDirs;
}

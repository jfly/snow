{ lib, ... }:

let
  moduleDir = ../nixos-modules;
in

{
  flake.nixosModules = lib.mapAttrs' (name: type: {
    name = lib.strings.removeSuffix ".nix" name;
    value = import (moduleDir + "/${name}");
  }) (builtins.readDir moduleDir);
}

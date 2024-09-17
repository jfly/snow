{ self, inputs, lib, flake-parts-lib, ... }:

let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    ;

  libDir = ../lib;
  libDirs = lib.filterAttrs (_name: type: type == "directory") (builtins.readDir libDir);
  args = {
    inherit inputs;
    flake = self;
  };
in

{
  options = {
    flake = mkSubmoduleOptions {
      lib = mkOption {
        description = ''
          Utility functions for use in this flake. Not really meant to be
          updated or used outside of this flake.
        '';
        type = types.lazyAttrsOf types.raw;
        readOnly = true;
        default = lib.mapAttrs (name: _type: import (libDir + "/${name}") args) libDirs;
      };
    };
  };
}

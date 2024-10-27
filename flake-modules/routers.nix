{
  self,
  inputs,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    ;
in
{
  imports = [
    (mkTransposedPerSystemModule {
      name = "routers";
      option = mkOption {
        type = types.lazyAttrsOf types.package;
        default = { };
        description = ''
          An attribute set of OpenWrt routers defined with [`nix-openwrt-imagebuilder`](https://github.com/astro/nix-openwrt-imagebuilder).
        '';
      };
      file = ./routers.nix;
    })
  ];

  perSystem =
    {
      self',
      inputs',
      system,
      pkgs,
      config,
      ...
    }:
    let
      pkgArgs = {
        flake = self;
        flake' = self' // {
          inherit config;
        };
        inherit inputs inputs' system;
      };
    in
    {
      routers = lib.filesystem.packagesFromDirectoryRecursive {
        callPackage = pkgs.newScope pkgArgs;
        directory = ../routers;
      };

      # Note: these router builds are impure (they read gitignored secrets from
      # the filesystem), so we don't add them to our flake checks (which should
      # be pure).
    };
}

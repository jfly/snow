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
      name = "containers";
      option = mkOption {
        type = types.lazyAttrsOf types.package;
        default = { };
        description = ''
          An attribute set of container images defined with [`streamLayeredImage`](https://nixos.org/manual/nixpkgs/stable/#ssec-pkgs-dockerTools-streamLayeredImage) to be built by [`nix build`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html).
        '';
      };
      file = ./containers.nix;
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
      containers = lib.filesystem.packagesFromDirectoryRecursive {
        callPackage = pkgs.newScope pkgArgs;
        directory = ../containers;
      };

      # Add checks to build each package.
      checks = lib.mapAttrs' (name: container: {
        # `checks` is a global namespace, so prefix each check so it
        # (hopefully) gets unique name.
        name = "containers/${name}";
        value = container;
      }) self'.containers;
    };
}

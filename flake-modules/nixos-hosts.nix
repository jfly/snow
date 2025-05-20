{
  lib,
  inputs,
  withSystem,
  ...
}@args:

let
  flake = args.self;
  hostsDir = ../hosts;

  evalConfig =
    { hostname }:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs flake;
        clan-core = null;
      };

      modules = [
        (hostsDir + "/${hostname}/configuration.nix")
        (
          { pkgs, ... }:
          {
            _module.args = {
              inputs' = withSystem pkgs.system ({ inputs', ... }: inputs');
              flake' = withSystem pkgs.system ({ self', ... }: self');
            };
          }
        )
      ];
    };

  hostDirs = lib.filterAttrs (_hostname: type: type == "directory") (builtins.readDir hostsDir);
  nixosConfigurations = lib.mapAttrs (hostname: _type: evalConfig { inherit hostname; }) hostDirs;
in

{
  imports = lib.mapAttrsToList (hostname: nixosConfiguration: {
    flake.nixosConfigurations.${hostname} = nixosConfiguration;
    perSystem.checks."hosts/${hostname}" = nixosConfiguration.config.system.build.toplevel;
  }) nixosConfigurations;
}

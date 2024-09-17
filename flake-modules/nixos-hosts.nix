{
  lib,
  inputs,
  withSystem,
  patched-nixpkgs,
  ...
}@args:

let
  flake = args.self;
  hostsDir = ../hosts;

  evalConfig =
    let
      ogEvalConfig = import "${patched-nixpkgs}/nixos/lib/eval-config.nix";
    in
    { hostname }:
    ogEvalConfig {
      # (copied from https://github.com/NixOS/nixpkgs/blob/9de34b26321950ad1ea29c6d12ad5adf01b0dc3b/flake.nix#L27-L30)
      # Allow system to be set modularly in nixpkgs.system.
      # We set it to null, to remove the "legacy" entrypoint's
      # non-hermetic default.
      system = null;

      specialArgs = {
        inherit inputs flake;
      };

      modules = [
        flake.nixosModules.shared
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
    perSystem.checks.${hostname} = nixosConfiguration.config.system.build.toplevel;
  }) nixosConfigurations;
}

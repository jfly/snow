{
  lib,
  self,
  inputs,
  withSystem,
  ...
}:

let
  machines = lib.pipe ../machines [
    builtins.readDir
    (lib.filterAttrs (_hostname: type: type == "directory"))
    (lib.mapAttrsToList (hostname: _type: hostname))
  ];
in
{
  imports = [
    inputs.clan-core.flakeModules.default
  ];
  clan = {
    meta.name = "snow";
    specialArgs = {
      inherit inputs;
      flake = self;
    };

    inventory = {
      instances.manman = {
        module = {
          input = "clan-core";
          name = "zerotier";
        };
        roles.controller.machines.fflewddur = { };
        roles.moon.machines = { };
        roles.peer.tags."all" = { };
      };
    };

    machines = lib.listToAttrs (
      map (hostname: {
        name = hostname;
        value = {
          imports = [
            (
              { pkgs, ... }:
              {
                _module.args = {
                  inputs' = withSystem pkgs.stdenv.hostPlatform.system ({ inputs', ... }: inputs');
                  flake' = withSystem pkgs.stdenv.hostPlatform.system ({ self', ... }: self');
                };
              }
            )
          ];
        };
      }) machines
    );
  };
}

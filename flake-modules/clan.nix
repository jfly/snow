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

    machines = lib.listToAttrs (
      map (hostname: {
        name = hostname;
        value = {
          imports = [
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
      }) machines
    );
  };
}

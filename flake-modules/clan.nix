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
      services.zerotier.default = {
        roles.controller.machines = [ "fflewddur" ];
        roles.peer.tags = [ "all" ];
      };
      services.data-mesher.default = {
        roles.admin.machines = [ "fflewddur" ];
        roles.peer.tags = [ "all" ];

        # This interface name is determined from the network id, but we don't
        # have eval-time access to it.
        # I hear this will get cleaner in the future when clan has a "unified
        # networking layer that the module can hook into and make saner default
        # decisions".
        config.network.interface = "zthjzvlscg";
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

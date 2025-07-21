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

      instances.data-mesher =
        let
          # This interface name is determined from the network id, but we don't
          # have eval-time access to it. So, you have to first deploy the
          # Zerotier network, and *then* fill this in.
          # This could be done in one shot if data-mesher supported Linux's
          # interface altnames. See
          # https://git.clan.lol/clan/data-mesher/issues/222.
          ztInterface = "zthjzvlscg";
        in
        {
          module = {
            input = "clan-core";
            name = "data-mesher";
          };
          roles.admin.machines.fflewddur = { };
          roles.peer.tags."all" = { };

          roles.admin.settings.network.tld = "m";

          roles.peer.settings.network.interface = ztInterface;
          roles.admin.settings.network.interface = ztInterface;
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

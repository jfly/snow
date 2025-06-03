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
      services.zerotier.mm = {
        roles.controller.machines = [ "fflewddur" ];
        roles.peer.tags = [ "all" ];
      };
      services.data-mesher.default = {
        roles.admin.machines = [ "fflewddur" ];
        roles.peer.tags = [ "all" ];

        # This interface name is determined from the network id, but we don't
        # have eval-time access to it. So, you have to first deploy the
        # Zerotier network, and *then* fill this in.
        # This could be done in one shot if data-mesher supported Linux's
        # interface altnames. See
        # https://git.clan.lol/clan/data-mesher/issues/222.
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

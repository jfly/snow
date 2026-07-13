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
        roles.controller.machines.fflewddur = {
          settings = {
            # How to add a mobile device to the network:
            # 1. Install ZeroTier One app.
            # 2. Connect to network "d4aa51eed904269f".
            #    - Enable "Network DNS".
            #      - Note: iOS has a bug where this doesn't work. Instead, select "Custom
            #              DNS" and add fflewddur's IPv6 address. See
            #              https://github.com/zerotier/ZeroTierOne/issues/2464
            #    - For macOS, disable DNS service coupling: `sudo scutil --disable-service-coupling on`
            #      TODO: write up a proper explanation for this. See notes in
            #            <https://github.com/apple-oss-distributions/configd/compare/main...jfly:configd:notes?expand=1>.
            #    - Add the node id below and redeploy fflewddur.
            allowedIds = [
              "b504d84a2e" # jfly phone
              "397eeab368" # jfly tablet
              "fce56a3a26" # ansible
              "06fda2b62d" # ram mbp
              "8d0ee1ad66" # ram desktop
              "c86a6ffd1f" # ospi
              "eee8a3e616" # gurgi
            ];
          };
        };
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

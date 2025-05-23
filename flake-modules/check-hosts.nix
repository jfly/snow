{ self, lib, ... }:

{
  perSystem.checks = lib.mapAttrs' (
    hostname: nixosConfiguration:
    lib.nameValuePair "hosts/${hostname}" nixosConfiguration.config.system.build.toplevel
  ) self.nixosConfigurations;
}

{
  flake,
  lib,
  python3,
  writeShellApplication,
}:
let
  hostToServices = lib.mapAttrs (
    name: nixosConfiguration:
    let
      myServices = lib.filter (service: service.hostedHere) (
        lib.attrValues nixosConfiguration.config.snow.services
      );
    in
    map (service: service.fqdn) myServices
  ) flake.nixosConfigurations;
  hostToNonemptyServices = lib.filterAttrs (
    host: services: builtins.length services > 0
  ) hostToServices;
in
writeShellApplication {
  name = "fix-host-to-services";
  runtimeInputs = [ (python3.withPackages (ps: [ ps.tomli-w ])) ];
  text = ''
    echo ${lib.escapeShellArg (builtins.toJSON hostToNonemptyServices)} | python -c "import json, sys, tomli_w; print(tomli_w.dumps(json.load(sys.stdin)))"
  '';
}

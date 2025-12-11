{
  flake,
  lib,
  python3,
  writers,
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
  json2Toml = writers.writePython3Bin "json2Toml" { libraries = ps: [ ps.tomli-w ]; } ''
    import json
    import sys
    import tomli_w

    print(tomli_w.dumps(json.load(sys.stdin)), end="")
  '';
in
writeShellApplication {
  name = "fix-host-to-services";
  runtimeInputs = [ (python3.withPackages (ps: [ ps.tomli-w ])) ];
  text = ''
    echo ${lib.escapeShellArg (builtins.toJSON hostToNonemptyServices)} | ${lib.getExe json2Toml}
  '';
}

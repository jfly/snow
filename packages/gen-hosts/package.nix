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
    # Only generate entries for domains on the overlay network. For others
    # ("public" hostnames), we need to figure out better solution for DNS. Right
    # now, they're handled by <iac/pulumi/app/dns.py>, but there's no glue
    # with the nixos configuration, and we're also missing out on split
    # DNS. It might make sense to revisit this if I ever get that bpir4
    # running nixos. Also read up on [hidden primary
    # name servers](https://dn.org/hidden-primary-name-servers-why-and-how/).
    map (service: service.fqdn) nixosConfiguration.config.snow.servicesOnThisMachine.private
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
  name = "gen-hosts";
  runtimeInputs = [ (python3.withPackages (ps: [ ps.tomli-w ])) ];
  text = ''
    echo ${lib.escapeShellArg (builtins.toJSON hostToNonemptyServices)} | ${lib.getExe json2Toml}
  '';
}

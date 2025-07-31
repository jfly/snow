{
  outerConfig,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # Trust certs from our self-hosted CA.
  # (This is copied from `nixos-modules/step-ca.nix`.)
  security.pki.certificateFiles = [
    outerConfig.clan.core.vars.generators.step-root-ca.files."ca.crt".path
  ];

  # This is copied from `nix/nixosModules/data-mesher/module.nix` in
  # `git.clan.lol/clan/data-mesher`.
  # TODO: ask file an issue upstream asking about how to make this work
  # inside of nixos containers.
  system.nssDatabases.hosts = lib.mkBefore [ "datamesher" ];
  system.nssModules =
    let
      nss-datamesher = inputs.clan-core.inputs.data-mesher.packages.${pkgs.system}.nss-datamesher;
    in
    [ nss-datamesher ];
}

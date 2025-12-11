{ outerConfig, ... }:
{
  # Trust certs from our self-hosted CA.
  # (This is copied from `nixos-modules/step-ca.nix`.)
  security.pki.certificateFiles = [
    outerConfig.clan.core.vars.generators.step-root-ca.files."ca.crt".path
  ];
}

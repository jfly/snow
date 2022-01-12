let
  mkHost = cfg: { ... }:
  {
    imports = [ cfg ];
    deployment.targetUser = "root";
  };
in
{
  "dallben" = mkHost dallben/configuration.nix;
  "fflewddur" = mkHost fflewddur/configuration.nix;
  "fflam" = mkHost fflam/configuration.nix;
}

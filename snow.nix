let
  mkHost = cfg: { ... }:
    {
      imports = [ cfg ];
      deployment.targetUser = "root";
    };
in
{
  "clark" = mkHost clark/configuration.nix;
  "dallben" = mkHost dallben/configuration.nix;
  "fflewddur" = mkHost fflewddur/configuration.nix;
  "fflam" = mkHost fflam/configuration.nix;
}

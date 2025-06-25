{
  config,
  lib,
  flake',
  ...
}:
let
  cfg = config.services.gaidns;
in
{
  options.services.gaidns = {
    enable = lib.mkEnableOption "gaidns dns server";

    package = lib.mkPackageOption flake'.packages "gaidns" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.gaidns = {
      description = "gaidns dns server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        CapabilityBoundingSet = "cap_net_bind_service";
        AmbientCapabilities = "cap_net_bind_service";
        NoNewPrivileges = true;
        DynamicUser = true;
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };
    };
  };
}

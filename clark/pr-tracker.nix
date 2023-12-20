{ pr-tracker }:
{ config, ... }:

let
  pgPort = config.services.postgresql.port;
  port = 7000;
  user = "pr-tracker";
in
{
  imports = [ pr-tracker.nixosModules.api ];

  services.postgresql.enable = true;
  services.postgresql.ensureDatabases = [ user ];
  services.postgresql.ensureUsers = [
    {
      name = user;
      ensureDBOwnership = true;
    }
  ];

  systemd.services.pr-tracker-api.environment.ROCKET_ADDRESS = "0.0.0.0";
  services.pr-tracker-api.enable = true;
  services.pr-tracker-api.port = port;
  services.pr-tracker-api.user = user;
  services.pr-tracker-api.databaseUrl = "postgresql:///${user}?host=/run/postgresql&port=${builtins.toString pgPort}";
  services.pr-tracker-api.localDb = true;
}

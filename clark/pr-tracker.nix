{ pr-tracker }:
{ config, ... }:

let
  pgPort = config.services.postgresql.port;
  port = 7000;
  user = "pr-tracker";
  databaseUrl = "postgresql:///${user}?host=/run/postgresql&port=${builtins.toString pgPort}";
in
{
  imports = [
    pr-tracker.nixosModules.api
    pr-tracker.nixosModules.fetcher
  ];

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
  services.pr-tracker-api.group = "pr-tracker";
  services.pr-tracker-api.databaseUrl = databaseUrl;
  services.pr-tracker-api.localDb = true;

  services.pr-tracker-fetcher.enable = true;
  services.pr-tracker-fetcher.user = user;
  services.pr-tracker-fetcher.group = "pr-tracker";
  systemd.services.pr-tracker-fetcher.environment.RUST_LOG = "info";
  services.pr-tracker-fetcher.branchPatterns = [ "*" ];
  services.pr-tracker-fetcher.databaseUrl = databaseUrl;
  services.pr-tracker-fetcher.localDb = true;
  services.pr-tracker-fetcher.githubApiTokenFile = "/run/pr-tracker-secrets/github.token"; # TODO: encrypt + version control this
  services.pr-tracker-fetcher.repo.owner = "NixOS";
  services.pr-tracker-fetcher.repo.name = "nixpkgs";
  services.pr-tracker-fetcher.onCalendar = "daily";
}

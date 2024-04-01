{ pr-tracker }:
{ config, ... }:

let
  pgPort = config.services.postgresql.port;
  internalApiPort = 7001;
  externalApiPort = 7000;
  user = "pr-tracker";
  dbUrlParams = {
    inherit user;
    host = "/run/postgresql";
    port = builtins.toString pgPort;
  };
in
{
  imports = [
    pr-tracker.nixosModules.api
    pr-tracker.nixosModules.fetcher
  ];

  # https://github.com/settings/tokens/1473000486
  age.secrets.pr-tracker-github-token = {
    owner = user;
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSA1UmxaaXpJMkpvT1Z2ajJQ
      a0FxMXZ1enl1TjBpWUpuRlFqM0hZZU1PY2swCkNMTE9MWXpoVm1jdVFLeUFHcE1K
      aEE0TXVsblRjaXlwN3p1alVwUEZBWU0KLS0tIEdSaE9vaHRSV0Y5d1NuY0YzaDhR
      dGNYZGlVeENNZHAvV01wd1o5QldxQ1UKSNuk1pVzjpqxQFV4qRYSPy8Lti6c8YER
      iDw5RABF1j34ucPAwRu91wbXxvftEGxURwa7un6Rr6Y8on8noTQR8OF7MsgL48Tf
      -----END AGE ENCRYPTED FILE-----
    '';
  };

  services.postgresql.enable = true;
  services.postgresql.ensureDatabases = [ user ];
  services.postgresql.ensureUsers = [
    {
      name = user;
      ensureDBOwnership = true;
    }
  ];

  # pr-tracker-api doesn't support changing the bind address to anything other
  # than 127.0.0.1. See
  # https://github.com/molybdenumsoftware/pr-tracker/issues/170
  # We work around this by exposing it via nginx.
  services.nginx = {
    enable = true;
    defaultHTTPListenPort = externalApiPort;
    virtualHosts."pr-tracker.snow.jflei.com" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString internalApiPort}";
      };
    };
  };

  services.pr-tracker.api.enable = true;
  services.pr-tracker.api.port = internalApiPort;
  services.pr-tracker.api.user = user;
  services.pr-tracker.api.group = "pr-tracker";
  services.pr-tracker.api.dbUrlParams = dbUrlParams;
  services.pr-tracker.api.localDb = true;

  services.pr-tracker.fetcher.enable = true;
  services.pr-tracker.fetcher.user = user;
  services.pr-tracker.fetcher.group = "pr-tracker";
  systemd.services.pr-tracker-fetcher.environment.RUST_LOG = "info";
  services.pr-tracker.fetcher.branchPatterns = [ "*" ];
  services.pr-tracker.fetcher.dbUrlParams = dbUrlParams;
  services.pr-tracker.fetcher.localDb = true;
  services.pr-tracker.fetcher.githubApiTokenFile = config.age.secrets.pr-tracker-github-token.path;
  services.pr-tracker.fetcher.repo.owner = "NixOS";
  services.pr-tracker.fetcher.repo.name = "nixpkgs";
  services.pr-tracker.fetcher.onCalendar = "daily";
}

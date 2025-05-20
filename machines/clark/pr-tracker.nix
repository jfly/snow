{ inputs, config, ... }:

let
  internalApiPort = 7001;
  externalApiPort = 7000;
in
{
  imports = [
    inputs.pr-tracker.nixosModules.api
    inputs.pr-tracker.nixosModules.fetcher
  ];

  # https://github.com/settings/tokens/1473000486
  clan.core.vars.generators.pr-tracker-github = {
    prompts."token" = {
      type = "hidden";
      persist = true;
    };
  };

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

  services.pr-tracker.db.createLocally = true;

  services.pr-tracker.api.enable = true;
  services.pr-tracker.api.port = internalApiPort;

  services.pr-tracker.fetcher.enable = true;
  systemd.services.pr-tracker-fetcher.environment.RUST_LOG = "info";
  services.pr-tracker.fetcher.branchPatterns = [
    "master"
    "nixos-*"
    "release-*"
  ];
  services.pr-tracker.fetcher.githubApiTokenFile =
    config.clan.core.vars.generators.pr-tracker-github.files."token".path;
  services.pr-tracker.fetcher.repo.owner = "NixOS";
  services.pr-tracker.fetcher.repo.name = "nixpkgs";
  services.pr-tracker.fetcher.onCalendar = "daily";
}

{ config, ... }:
let
  inherit (config.snow) services;
in
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3100;
        enforce_domain = true;
        domain = services.grafana.fqdn;
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
        }
      ];
    };
  };

  snow.services.grafana.proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";

  snow.backup.paths = [ config.services.grafana.dataDir ];
}

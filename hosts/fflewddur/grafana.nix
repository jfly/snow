{ config, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3100;
        enforce_domain = true;
        domain = "grafana.snow.jflei.com";
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

  services.nginx.virtualHosts."grafana.snow.jflei.com" = {
    locations."/" = {
      proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
  };

  snow.backup.paths = [ config.services.grafana.dataDir ];
}

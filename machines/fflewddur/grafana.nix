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

  services.data-mesher.settings.host.names = [ services.grafana.sld ];
  services.nginx.virtualHosts.${services.grafana.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
  };

  snow.backup.paths = [ config.services.grafana.dataDir ];
}

{ config, ... }:
let
  port = config.services.radarr.settings.server.port;
in
{
  services.radarr = {
    enable = true;
    group = "media";
  };

  snow.services.radarr.proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";

  systemd.services.radarr = {
    vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };
  };

  vpnNamespaces.wg.portMappings = [
    {
      from = port;
      to = port;
      protocol = "tcp";
    }
  ];

  snow.backup.paths = [
    config.services.radarr.dataDir
  ];
}

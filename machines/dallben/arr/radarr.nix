{ config, ... }:
let
  inherit (config.snow) services;
  port = config.services.radarr.settings.server.port;
in
{
  services.radarr = {
    enable = true;
    group = "media";
  };

  services.data-mesher.settings.host.names = [ services.radarr.sld ];
  services.nginx.virtualHosts.${services.radarr.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";
    };
  };

  systemd.services.radarr = {
    after = [ "mnt-media.mount" ];
    requires = [ "mnt-media.mount" ];
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

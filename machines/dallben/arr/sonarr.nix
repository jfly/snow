{ config, ... }:
let
  inherit (config.snow) services;
  port = config.services.sonarr.settings.server.port;
in
{
  services.sonarr = {
    enable = true;
    group = "media";
  };

  services.data-mesher.settings.host.names = [ services.sonarr.sld ];
  services.nginx.virtualHosts.${services.sonarr.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";
    };
  };

  systemd.services.sonarr = {
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
    config.services.sonarr.dataDir
  ];
}

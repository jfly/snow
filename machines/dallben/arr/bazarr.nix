{ config, ... }:
let
  inherit (config.snow) services;
  port = config.services.bazarr.listenPort;
in
{
  services.bazarr = {
    enable = true;
    group = "media";
  };

  services.data-mesher.settings.host.names = [ services.bazarr.sld ];
  services.nginx.virtualHosts.${services.bazarr.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";
    };
  };

  systemd.services.bazarr = {
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
    config.services.bazarr.dataDir
  ];
}

{ config, ... }:
let
  port = config.services.bazarr.listenPort;
in
{
  services.bazarr = {
    enable = true;
    group = "media";
  };

  snow.services.bazarr.proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";

  systemd.services.bazarr = {
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

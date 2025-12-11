{ config, ... }:
let
  port = config.services.jackett.port;
in
{
  services.jackett.enable = true;

  snow.services.jackett.proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";

  systemd.services.jackett = {
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
    config.services.jackett.dataDir
  ];
}

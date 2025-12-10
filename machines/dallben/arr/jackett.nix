{ config, ... }:
let
  inherit (config.snow) services;
  port = config.services.jackett.port;
in
{
  services.jackett.enable = true;

  services.data-mesher.settings.host.names = [ services.jackett.sld ];
  services.nginx.virtualHosts.${services.jackett.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";
    };
  };

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

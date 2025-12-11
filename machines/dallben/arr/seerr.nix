{ config, ... }:
let
  port = config.services.jellyseerr.port;
in
{
  services.jellyseerr.enable = true;

  snow.services.seerr.proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";

  systemd.services.jellyseerr = {
    # Set `HOME` as a workaround for <https://github.com/Maroka-chan/VPN-Confinement/issues/36>.
    environment.HOME = config.services.jellyseerr.configDir;
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
    config.services.jellyseerr.configDir
  ];
}

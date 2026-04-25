{ config, ... }:
let
  port = config.services.seerr.port;
in
{
  services.seerr.enable = true;

  snow.services.seerr.proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString port}";

  systemd.services.seerr = {
    # Set `HOME` as a workaround for <https://github.com/Maroka-chan/VPN-Confinement/issues/36>.
    environment.HOME = config.services.seerr.configDir;
    vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };
    unitConfig = {
      RequiresMountsFor = "/mnt/media";
    };
  };

  vpnNamespaces.wg.portMappings = [
    {
      from = port;
      to = port;
      protocol = "tcp";
    }
  ];
}

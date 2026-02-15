{ config, ... }:
{
  services.transmission = {
    enable = true;
    group = "media";
    settings = {
      download-dir = "/mnt/media/torrents";
      incomplete-dir = "/mnt/media/torrents/incomplete";

      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
      rpc-authentication-required = false;

      peer-port = 61207;
      port-forwarding-enabled = false;
      download-queue-enabled = false;
      ratio-limit-enabled = true;
      ratio-limit = 2;
      # Allow group to write to these files (the default is 022).
      umask = 2;
    };
  };

  systemd.services.transmission = {
    vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };
  };

  vpnNamespaces.wg.portMappings = [
    {
      from = config.services.transmission.settings.rpc-port;
      to = config.services.transmission.settings.rpc-port;
      protocol = "tcp";
    }
  ];

  snow.services.torrents.proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString config.services.transmission.settings.rpc-port}";

  snow.backup.paths = [
    config.services.transmission.home
  ];
}
